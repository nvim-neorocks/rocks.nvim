---@mod rocks.operations.sync
--
-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    06 Jul 2024
-- Updated:    06 Jul 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- This module handles the sync operation.
--
---@brief ]]

local operations = {}

local constants = require("rocks.constants")
local log = require("rocks.log")
local config = require("rocks.config.internal")
local state = require("rocks.state")
local helpers = require("rocks.operations.helpers")
local handlers = require("rocks.operations.handlers")
local nio = require("nio")
local progress = require("fidget.progress")
local adapter = require("rocks.adapter")

--- Synchronizes the user rocks with the physical state on the current machine.
--- - Installs missing rocks
--- - Ensures that the correct versions are installed
--- - Uninstalls unneeded rocks
---@param user_rocks? table<rock_name, RockSpec|string> loaded from rocks.toml if `nil`
---@param on_complete? function
operations.sync = function(user_rocks, on_complete)
    log.info("syncing...")
    nio.run(function()
        helpers.semaphore.with(function()
            local progress_handle = progress.handle.create({
                title = "Syncing",
                lsp_client = { name = constants.ROCKS_NVIM },
            })

            ---@type ProgressHandle[]
            local error_handles = {}
            ---@param message string
            local function report_error(message)
                log.error(("SYNC ERROR: %s"):format(message))
                table.insert(
                    error_handles,
                    progress.handle.create({
                        title = "Error",
                        lsp_client = { name = constants.ROCKS_NVIM },
                        message = message,
                    })
                )
            end
            local function report_progress(message)
                progress_handle:report({
                    message = message,
                })
            end
            if user_rocks == nil then
                -- Read or create a new config file and decode it
                -- NOTE: This does not use parse_user_rocks
                -- because we decode with toml-edit.parse_as_tbl, not toml-edit.parse
                user_rocks = config.get_user_rocks()
            end

            for name, data in pairs(user_rocks) do
                -- TODO(vhyrro): Good error checking
                if type(data) == "string" then
                    ---@type RockSpec
                    user_rocks[name] = {
                        name = name,
                        version = data,
                    }
                else
                    user_rocks[name].name = name
                end
            end
            ---@cast user_rocks table<rock_name, RockSpec>

            local installed_rocks = state.installed_rocks()

            local sync_status = state.out_of_sync_rocks(user_rocks)

            local ct = 1

            ---@class SyncSkippedRock
            ---@field spec RockSpec
            ---@field reason string

            ---@type SyncSkippedRock[]
            local skipped_rocks = {}

            for _, key in ipairs(sync_status.to_install) do
                -- Save skipped rocks for later, when an external handler may have been bootstrapped
                if not user_rocks[key].version then
                    table.insert(skipped_rocks, {
                        spec = user_rocks[key],
                        reason = "No version specified",
                    })
                    goto skip_install
                elseif key:lower() ~= key then
                    table.insert(skipped_rocks, {
                        spec = user_rocks[key],
                        reason = "Name is not lowercase",
                    })
                    goto skip_install
                end
                nio.scheduler()
                progress_handle:report({
                    message = ("Installing: %s"):format(key),
                })
                -- If the plugin version is a development release then we pass `dev` as the version to the install function
                -- as it gets converted to the `--dev` flag on there, allowing luarocks to pull the `scm-1` rockspec manifest
                if vim.startswith(user_rocks[key].version, "scm-") then
                    user_rocks[key].version = "dev"
                end
                local future = helpers.install(user_rocks[key])
                local success = pcall(future.wait)

                ct = ct + 1
                nio.scheduler()
                if not success then
                    report_error(("Failed to install %s."):format(key))
                end
                progress_handle:report({
                    message = ("Installed: %s"):format(key),
                })
                ::skip_install::
            end

            -- Sync actions handled by external modules that have registered handlers
            for _, callback in pairs(sync_status.external_actions) do
                ct = ct + 1
                callback(report_progress, report_error, helpers.manage_rock_stub)
            end

            -- rocks.nvim sync handlers should be installed now.
            -- try installing any rocks that rocks.nvim could not handle itself
            for _, skipped_rock in ipairs(skipped_rocks) do
                local spec = skipped_rock.spec
                ct = ct + 1
                local callback = handlers.get_sync_handler_callback(spec)
                if callback then
                    callback(report_progress, report_error, helpers.manage_rock_stub)
                else
                    report_error(("Failed to install %s: %s"):format(spec.name, skipped_rock.reason))
                end
            end

            for _, key in ipairs(sync_status.to_updowngrade) do
                local parse_installed_version_success, installed_version =
                    pcall(vim.version.parse, installed_rocks[key].version)
                -- in nvim < 0.11, vim.version.parse throws an error on non-semver args
                local is_installed_version_semver = parse_installed_version_success and installed_version ~= nil
                local parse_user_version_success, user_version =
                    pcall(vim.version.parse, user_rocks[key].version or "dev")
                local is_user_version_semver = parse_user_version_success and installed_version ~= nil
                local is_downgrading = not is_installed_version_semver and is_user_version_semver
                    or is_user_version_semver and is_installed_version_semver and user_version < installed_version

                nio.scheduler()
                progress_handle:report({
                    message = is_downgrading and ("Downgrading: %s"):format(key) or ("Updating: %s"):format(key),
                })

                local future = helpers.install(user_rocks[key])
                local success = pcall(future.wait)

                ct = ct + 1
                nio.scheduler()
                if not success then
                    report_error(
                        is_downgrading and ("Failed to downgrade %s"):format(key)
                            or ("Failed to upgrade %s"):format(key)
                    )
                end
                progress_handle:report({
                    message = is_downgrading and ("Downgraded: %s"):format(key) or ("Upgraded: %s"):format(key),
                })
            end

            ---@type string[]
            local prunable_rocks

            -- Determine dependencies of installed user rocks, so they can be excluded from rocks to prune
            -- NOTE(mrcjkb): This has to be done after installation,
            -- so that we don't prune dependencies of newly installed rocks.
            local function refresh_rocks_state()
                sync_status.to_prune = vim.empty_dict()
                installed_rocks = state.installed_rocks()
                local key_list = nio.fn.keys(vim.tbl_deep_extend("force", installed_rocks, user_rocks))
                for _, key in ipairs(key_list) do
                    if not user_rocks[key] and installed_rocks[key] then
                        table.insert(sync_status.to_prune, key)
                    end
                end
                local dependencies = vim.empty_dict()
                ---@cast dependencies {[string]: RockDependency}
                for _, installed_rock in pairs(installed_rocks) do
                    for k, v in pairs(state.rock_dependencies(installed_rock)) do
                        dependencies[k] = v
                    end
                end

                prunable_rocks = vim.iter(sync_status.to_prune)
                    :filter(function(key)
                        return dependencies[key] == nil
                    end)
                    :totable()
            end

            refresh_rocks_state()

            handlers.prune_user_rocks(user_rocks, report_progress, report_error)

            if ct == 0 and vim.tbl_isempty(prunable_rocks) then
                local message = "Everything is in-sync!"
                log.info(message)
                nio.scheduler()
                progress_handle:report({ message = message, percentage = 100 })
                progress_handle:finish()
                return
            end

            ---@diagnostic disable-next-line: invisible
            local user_rock_names = nio.fn.keys(user_rocks)

            repeat
                -- Prune rocks sequentially, to prevent conflicts
                for _, key in ipairs(prunable_rocks) do
                    nio.scheduler()
                    progress_handle:report({ message = ("Removing: %s"):format(key) })

                    local success = helpers.remove_recursive(installed_rocks[key].name, user_rock_names)

                    ct = ct + 1
                    nio.scheduler()
                    if not success then
                        report_error(("Failed to remove %s."):format(key))
                    else
                        progress_handle:report({
                            message = ("Removed: %s"):format(key),
                        })
                    end
                end
                refresh_rocks_state()
            until vim.tbl_isempty(prunable_rocks)

            adapter.synchronise_site_symlinks()
            vim
                .iter(sync_status.to_install)
                ---@param rock_name string
                :map(function(rock_name)
                    return user_rocks[rock_name]
                end)
                :filter(function(rock_spec)
                    return rock_spec ~= nil
                end)
                :each(helpers.dynamic_load)

            helpers.postInstall()
            if not vim.tbl_isempty(error_handles) then
                local message = "Sync completed with errors! Run ':Rocks log' for details."
                log.error(message)
                progress_handle:report({
                    title = "Error",
                    message = message,
                })
                progress_handle:cancel()
                for _, error_handle in pairs(error_handles) do
                    error_handle:cancel()
                end
            else
                progress_handle:finish()
            end
            if on_complete then
                on_complete()
            end
        end)
    end)
end

return operations
