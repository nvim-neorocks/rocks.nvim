---@mod rocks.operations
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    07 Mar 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- This module handles all the operations that has something to do with
-- luarocks. Installing, uninstalling, updating, etc.
--
---@brief ]]

local constants = require("rocks.constants")
local log = require("rocks.log")
local fs = require("rocks.fs")
local config = require("rocks.config.internal")
local state = require("rocks.state")
local cache = require("rocks.cache")
local helpers = require("rocks.operations.helpers")
local handlers = require("rocks.operations.handlers")
local nio = require("nio")
local progress = require("fidget.progress")

local operations = {}

operations.register_handler = handlers.register_handler

--- `vim.schedule` a callback in an async context,
--- waiting for it to be executed
---@type async fun(func: fun())
local vim_schedule_nio_wait = nio.create(function(func)
    ---@cast func fun()
    local future = nio.control.future()
    vim.schedule(function()
        func()
        future.set(true)
    end)
    future.wait()
end, 1)

---@class (exact) Future
---@field wait fun() Wait in an async context. Does not block in a sync context
---@field wait_sync fun() Wait in a sync context

---@alias rock_table table<rock_name, Rock>

---Decode the user rocks from rocks.toml, creating a default config file if it does not exist
---@return MutRocksTomlRef
local function parse_rocks_toml()
    local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
    return require("toml_edit").parse(config_file)
end

---@param counter number
---@param total number
local function get_percentage(counter, total)
    return counter > 0 and math.min(100, math.floor((counter / total) * 100)) or 0
end

--- Synchronizes the user rocks with the physical state on the current machine.
--- - Installs missing rocks
--- - Ensures that the correct versions are installed
--- - Uninstalls unneeded rocks
---@param user_rocks? table<rock_name, RockSpec|string> loaded from rocks.toml if `nil`
operations.sync = function(user_rocks)
    log.info("syncing...")
    nio.run(function()
        local progress_handle = progress.handle.create({
            title = "Syncing",
            lsp_client = { name = constants.ROCKS_NVIM },
            percentage = 0,
        })

        ---@type ProgressHandle[]
        local error_handles = {}
        ---@param message string
        local function report_error(message)
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
            -- NOTE: This does not use parse_user_rocks because we decode with toml, not toml-edit
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

        -- The following code uses `nio.fn.keys` instead of `vim.tbl_keys`
        -- which invokes the scheduler and works in async contexts.
        ---@type string[]
        ---@diagnostic disable-next-line: invisible
        local key_list = nio.fn.keys(vim.tbl_deep_extend("force", installed_rocks, user_rocks))

        local external_actions = vim.empty_dict()
        ---@cast external_actions rock_handler_callback[]
        local to_install = vim.empty_dict()
        ---@cast to_install string[]
        local to_updowngrade = vim.empty_dict()
        ---@cast to_updowngrade string[]
        local to_prune = vim.empty_dict()
        ---@cast to_prune string[]
        for _, key in ipairs(key_list) do
            local user_rock = user_rocks[key]
            local callback = user_rock and handlers.get_sync_handler_callback(user_rock)
            if callback then
                table.insert(external_actions, callback)
            elseif user_rocks and not installed_rocks[key] then
                table.insert(to_install, key)
            elseif
                user_rock
                and user_rock.version
                and installed_rocks[key]
                and user_rock.version ~= installed_rocks[key].version
            then
                table.insert(to_updowngrade, key)
            elseif not user_rock and installed_rocks[key] then
                table.insert(to_prune, key)
            end
        end

        local ct = 1
        ---@diagnostic disable-next-line: invisible
        local action_count = #to_install + #to_updowngrade + #to_prune + #external_actions

        local function get_progress_percentage()
            return get_percentage(ct, action_count)
        end

        -- Sync actions handled by external modules that have registered handlers
        for _, callback in ipairs(external_actions) do
            ct = ct + 1
            callback(report_progress, report_error)
        end

        for _, key in ipairs(to_install) do
            nio.scheduler()
            if not user_rocks[key].version then
                -- TODO(vhyrro): Maybe add a rocks option that warns on malformed rocks?
                goto skip_install
            end
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
                progress_handle:report({ percentage = get_progress_percentage() })
                report_error(("Failed to install %s."):format(key))
            end
            progress_handle:report({
                message = ("Installed: %s"):format(key),
                percentage = get_progress_percentage(),
            })
            ::skip_install::
        end
        for _, key in ipairs(to_updowngrade) do
            local is_installed_version_semver, installed_version =
                pcall(vim.version.parse, installed_rocks[key].version)
            local is_user_version_semver, user_version = pcall(vim.version.parse, user_rocks[key].version or "dev")
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
                progress_handle:report({
                    percentage = get_progress_percentage(),
                })
                report_error(
                    is_downgrading and ("Failed to downgrade %s"):format(key) or ("Failed to upgrade %s"):format(key)
                )
            end
            progress_handle:report({
                percentage = get_progress_percentage(),
                message = is_downgrading and ("Downgraded: %s"):format(key) or ("Upgraded: %s"):format(key),
            })
        end

        -- Determine dependencies of installed user rocks, so they can be excluded from rocks to prune
        -- NOTE(mrcjkb): This has to be done after installation,
        -- so that we don't prune dependencies of newly installed rocks.
        -- TODO: This doesn't guarantee that all rocks that can be pruned will be pruned.
        -- Typically, another sync will fix this. Maybe we should do some sort of repeat... until?
        installed_rocks = state.installed_rocks()
        local dependencies = vim.empty_dict()
        ---@cast dependencies {[string]: RockDependency}
        for _, installed_rock in pairs(installed_rocks) do
            for k, v in pairs(state.rock_dependencies(installed_rock)) do
                dependencies[k] = v
            end
        end

        handlers.prune_user_rocks(user_rocks, report_progress, report_error)

        ---@type string[]
        local prunable_rocks = vim.iter(to_prune)
            :filter(function(key)
                return dependencies[key] == nil
            end)
            :totable()

        action_count = #to_install + #to_updowngrade + #prunable_rocks

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
        -- Prune rocks sequentially, to prevent conflicts
        for _, key in ipairs(prunable_rocks) do
            nio.scheduler()
            progress_handle:report({ message = ("Removing: %s"):format(key) })

            local success = helpers.remove_recursive(installed_rocks[key].name, user_rock_names)

            ct = ct + 1
            nio.scheduler()
            if not success then
                -- TODO: Keep track of failures: #55
                progress_handle:report({
                    percentage = get_progress_percentage(),
                })
                report_error(("Failed to remove %s."):format(key))
            else
                progress_handle:report({
                    message = ("Removed: %s"):format(key),
                    percentage = get_progress_percentage(),
                })
            end
        end

        if not vim.tbl_isempty(error_handles) then
            local message = "Sync completed with errors!"
            log.error(message)
            progress_handle:report({
                title = "Error",
                message = message,
                percentage = 100,
            })
            progress_handle:cancel()
            for _, error_handle in pairs(error_handles) do
                error_handle:cancel()
            end
        else
            progress_handle:finish()
        end
        cache.populate_removable_rock_cache()

        -- Re-generate help tags
        if config.generate_help_pages then
            vim.cmd("helptags ALL")
        end
    end)
end

--- Attempts to update every available rock if it is not pinned.
--- This function invokes a UI.
operations.update = function()
    local progress_handle = progress.handle.create({
        title = "Updating",
        message = "Checking for updates...",
        lsp_client = { name = constants.ROCKS_NVIM },
        percentage = 0,
    })

    nio.run(function()
        ---@type ProgressHandle[]
        local error_handles = {}
        ---@param message string
        local function report_error(message)
            table.insert(
                error_handles,
                progress.handle.create({
                    title = "Error",
                    lsp_client = { name = constants.ROCKS_NVIM },
                    message = message,
                })
            )
        end

        local user_rocks = parse_rocks_toml()

        local outdated_rocks = state.outdated_rocks()
        local external_update_handlers = handlers.get_update_handler_callbacks(user_rocks)

        local total_update_count = #outdated_rocks + #external_update_handlers

        nio.scheduler()

        local ct = 0
        for name, rock in pairs(outdated_rocks) do
            nio.scheduler()
            progress_handle:report({
                message = name,
            })
            local future = helpers.install({
                name = name,
                version = rock.target_version,
            })
            local success, ret = pcall(future.wait)
            ct = ct + 1
            nio.scheduler()
            if success then
                ---@type rock_name
                local rock_name = ret.name
                local user_rock = user_rocks.plugins[rock_name]
                if user_rock and user_rock.version then
                    -- Rock is configured as a table -> Update version.
                    user_rocks.plugins[rock_name].version = ret.version
                elseif user_rock then -- Only insert the version if there's an entry in rocks.toml
                    user_rocks.plugins[rock_name] = ret.version
                end
                progress_handle:report({
                    message = ("Updated %s: %s -> %s"):format(rock.name, rock.version, rock.target_version),
                    percentage = get_percentage(ct, total_update_count),
                })
            else
                report_error(("Failed to update %s."):format(rock.name))
                progress_handle:report({
                    percentage = get_percentage(ct, total_update_count),
                })
            end
        end
        for _, handler in pairs(external_update_handlers) do
            local function report_progress(message)
                progress_handle:report({
                    message = message,
                })
            end
            handler(report_progress, report_error)
            progress_handle:report({
                percentage = get_percentage(ct, total_update_count),
            })
            ct = ct + 1
        end

        if vim.tbl_isempty(outdated_rocks) and vim.tbl_isempty(external_update_handlers) then
            progress_handle:report({ message = "Nothing to update!", percentage = 100 })
        else
            vim_schedule_nio_wait(function()
                fs.write_file(config.config_path, "w", tostring(user_rocks))
            end)
        end
        nio.scheduler()
        if not vim.tbl_isempty(error_handles) then
            local message = "Update completed with errors!"
            log.error(message)
            progress_handle:report({
                title = "Error",
                message = message,
                percentage = 100,
            })
            progress_handle:cancel()
            for _, error_handle in pairs(error_handles) do
                error_handle:cancel()
            end
        else
            progress_handle:finish()
        end
        cache.populate_removable_rock_cache()

        -- Re-generate help tags
        if config.generate_help_pages then
            vim.cmd("helptags ALL")
        end
    end)
end

--- Prompt to retry an installation searching the dev manifest, if the version
--- is not "dev" or "scm"
---@param arg_list string[] #Argument list, potentially used by external handlers
---@param rock_name rock_name #The rock name
---@param version? string #The version of the rock to use
local function prompt_retry_install_with_dev(arg_list, rock_name, version)
    if version ~= "dev" then
        local yesno = vim.fn.input("Could not find " .. rock_name .. ". Search for 'dev' version? y/n: ")
        print("\n ")
        if string.match(yesno, "^y.*") then
            nio.run(function()
                operations.add(arg_list, rock_name, "dev")
            end)
        end
    end
end

--- Adds a new rock and updates the `rocks.toml` file
---@param arg_list string[] #Argument list, potentially used by external handlers
---@param rock_name rock_name #The rock name
---@param version? string #The version of the rock to use
operations.add = function(arg_list, rock_name, version)
    local progress_handle = progress.handle.create({
        title = "Installing",
        lsp_client = { name = constants.ROCKS_NVIM },
    })

    nio.run(function()
        local user_rocks = parse_rocks_toml()
        local handler = handlers.get_install_handler_callback(user_rocks, arg_list)
        if type(handler) == "function" then
            local function report_progress(message)
                progress_handle:report({
                    message = message,
                })
            end
            local function report_error(message)
                progress_handle:report({
                    title = "Error",
                    message = message,
                })
                progress_handle:cancel()
            end
            handler(report_progress, report_error)
            vim_schedule_nio_wait(function()
                fs.write_file(config.config_path, "w", tostring(user_rocks))
                progress_handle:finish()
            end)
            return
        end
        progress_handle:report({
            message = version and ("%s -> %s"):format(rock_name, version) or rock_name,
        })
        local future = helpers.install({
            name = rock_name,
            version = version,
        })
        ---@type boolean, Rock | string
        local success, installed_rock = pcall(future.wait)
        vim_schedule_nio_wait(function()
            if not success then
                local stderr = installed_rock
                ---@cast stderr string
                local not_found = stderr:match("No results matching query were found") ~= nil
                local message = ("Installation of %s failed"):format(rock_name)
                if not_found then
                    message = ("Could not find %s %s"):format(rock_name, version or "")
                end
                progress_handle:report({
                    title = "Error",
                    message = message,
                })
                if not_found then
                    prompt_retry_install_with_dev(arg_list, rock_name, version)
                end
                progress_handle:cancel()
                return
            end
            progress_handle:report({
                title = "Installation successful",
                message = ("%s -> %s"):format(installed_rock.name, installed_rock.version),
                percentage = 100,
            })
            -- FIXME(vhyrro): This currently works in a half-baked way.
            -- The `toml-edit` libary will create a new empty table here, but if you were to try
            -- and populate the table upfront then none of the values will be registered by `toml-edit`.
            -- This should be fixed ASAP.
            if not user_rocks.plugins then
                local plugins = vim.empty_dict()
                ---@cast plugins rock_table
                user_rocks.plugins = plugins
            end

            -- Set installed version as `scm-1` if development version has been installed
            if version == "dev" then
                installed_rock.version = "scm-1"
            end
            local user_rock = user_rocks.plugins[rock_name]
            if user_rock and user_rock.version then
                -- Rock already exists in rock.toml and is configured as a table -> Update version.
                user_rocks.plugins[rock_name].version = installed_rock.version
            else
                user_rocks.plugins[rock_name] = installed_rock.version
            end
            fs.write_file(config.config_path, "w", tostring(user_rocks))
            if success then
                progress_handle:finish()
            else
                progress_handle:cancel()
            end
        end)
        cache.populate_removable_rock_cache()

        -- Re-generate help tags
        if config.generate_help_pages then
            vim.cmd("helptags ALL")
        end
    end)
end

---Uninstall a rock, pruning it from rocks.toml.
---@param rock_name string
operations.prune = function(rock_name)
    local progress_handle = progress.handle.create({
        title = "Pruning",
        lsp_client = { name = constants.ROCKS_NVIM },
    })
    nio.run(function()
        local user_config = parse_rocks_toml()
        if user_config.plugins then
            user_config.plugins[rock_name] = nil
        end
        if user_config.rocks then
            user_config.rocks[rock_name] = nil
        end
        local user_rock_names =
            ---@diagnostic disable-next-line: invisible
            nio.fn.keys(vim.tbl_deep_extend("force", user_config.rocks or {}, user_config.plugins or {}))
        local success = helpers.remove_recursive(rock_name, user_rock_names, progress_handle)
        vim_schedule_nio_wait(function()
            fs.write_file(config.config_path, "w", tostring(user_config))
            if success then
                progress_handle:finish()
            else
                local message = "Prune completed with errors!"
                log.error(message)
                progress_handle:report({
                    title = "Error",
                    message = message,
                })
                progress_handle:cancel()
            end
        end)
        cache.populate_removable_rock_cache()
    end)
end

return operations
