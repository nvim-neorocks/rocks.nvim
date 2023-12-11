---@mod rocks.operations
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    09 Dec 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
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
local luarocks = require("rocks.luarocks")
local nio = require("nio")
local progress = require("fidget.progress")

local operations = {}

---@class (exact) Future
---@field wait fun() Wait in an async context. Does not block in a sync context
---@field wait_sync fun() Wait in a sync context

---@alias rock_config_table { [string]: Rock|string }
---@alias rock_table { [string]: Rock }

---Decode the user rocks from rocks.toml, creating a default config file if it does not exist
---@return { rocks?: rock_config_table, plugins?: rock_config_table }
local function parse_user_rocks()
    local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
    return require("toml_edit").parse(config_file)
end

---@param name string
---@param version? string
---@param progress_handle? ProgressHandle
---@return Future
operations.install = function(name, version, progress_handle)
    cache.invalidate_removable_rocks()
    local message = version and ("Installing: %s -> %s"):format(name, version) or ("Installing: %s"):format(name)
    log.info(message)
    if progress_handle then
        progress_handle:report({ message = message })
    end
    -- TODO(vhyrro): Input checking on name and version
    local future = nio.control.future()
    local install_cmd = {
        "install",
        name,
    }
    if version then
        -- If specified version is dev then install the `scm-1` version of the rock
        if version == "dev" then
            table.insert(install_cmd, 2, "--dev")
        else
            table.insert(install_cmd, version)
        end
    end
    local systemObj = luarocks.cli(install_cmd, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code ~= 0 then
            message = ("Failed to install %s"):format(name)
            log.error(message)
            if progress_handle then
                progress_handle:report({ message = message })
            end
            future.set_error(sc.stderr)
        else
            ---@type Rock
            local installed_rock = {
                name = name,
                -- The `gsub` makes sure to escape all punctuation characters
                -- so they do not get misinterpreted by the lua pattern engine.
                -- We also exclude `-<specrev>` from the version match.
                version = sc.stdout:match(name:gsub("%p", "%%%1") .. "%s+([^-%s]+)"),
            }
            message = ("Installed: %s -> %s"):format(installed_rock.name, installed_rock.version)
            log.info(message)
            if progress_handle then
                progress_handle:report({ message = message })
            end
            future.set(installed_rock)
        end
    end)
    return {
        wait = future.wait,
        wait_sync = function()
            systemObj:wait()
        end,
    }
end

---Removes a rock
---@param name string
---@param progress_handle? ProgressHandle
---@return Future
operations.remove = function(name, progress_handle)
    cache.invalidate_removable_rocks()
    local message = ("Uninstalling: %s"):format(name)
    log.info(message)
    if progress_handle then
        progress_handle:report({ message = message })
    end
    local future = nio.control.future()
    local systemObj = luarocks.cli({
        "remove",
        name,
    }, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code ~= 0 then
            message = ("Failed to remove %s."):format(name)
            if progress_handle then
                progress_handle:report({ message = message })
            end
            future.set_error(sc.stderr)
        else
            log.info(("Uninstalled: %s"):format(name))
            future.set(sc)
        end
    end)
    return {
        wait = future.wait,
        wait_sync = function()
            systemObj:wait()
        end,
    }
end

---Removes a rock, and recursively removes its dependencies
---if they are no longer needed.
---@type async fun(name: string, keep: string[], progress_handle?: ProgressHandle): boolean
operations.remove_recursive = nio.create(function(name, keep, progress_handle)
    ---@cast name string
    local dependencies = state.rock_dependencies(name)
    local future = operations.remove(name, progress_handle)
    local success, _ = pcall(future.wait)
    if not success then
        return false
    end
    local removable_rocks = state.query_removable_rocks()
    local removable_dependencies = vim.iter(dependencies)
        :filter(function(rock_name)
            return vim.list_contains(removable_rocks, rock_name) and not vim.list_contains(keep, rock_name)
        end)
        :totable()
    for _, dep in pairs(removable_dependencies) do
        if vim.list_contains(removable_rocks, dep.name) then
            success = success and operations.remove_recursive(dep.name, keep, progress_handle)
        end
    end
    return success
end)

--- Synchronizes the user rocks with the physical state on the current machine.
--- - Installs missing rocks
--- - Ensures that the correct versions are installed
--- - Uninstalls unneeded rocks
---@param user_rocks? { [string]: Rock|string } loaded from rocks.toml if `nil`
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

        if user_rocks == nil then
            -- Read or create a new config file and decode it
            -- NOTE: This does not use parse_user_rocks because we decode with toml, not toml-edit
            local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
            local user_config = require("toml").decode(config_file)

            -- Merge `rocks` and `plugins` fields as they are just an eye-candy separator for clarity purposes
            user_rocks = vim.tbl_deep_extend("force", user_config.rocks or {}, user_config.plugins or {})
        end

        for name, data in pairs(user_rocks) do
            -- TODO(vhyrro): Good error checking
            if type(data) == "string" then
                user_rocks[name] = {
                    name = name,
                    version = data,
                }
            end
        end
        ---@cast user_rocks rock_table

        local installed_rocks = state.installed_rocks()

        -- The following code uses `nio.fn.keys` instead of `vim.tbl_keys`
        -- which invokes the scheduler and works in async contexts.
        ---@type string[]
        ---@diagnostic disable-next-line: invisible
        local key_list = nio.fn.keys(vim.tbl_deep_extend("force", installed_rocks, user_rocks))

        local to_install = vim.empty_dict()
        ---@cast to_install string[]
        local to_updowngrade = vim.empty_dict()
        ---@cast to_updowngrade string[]
        local to_prune = vim.empty_dict()
        ---@cast to_prune string[]
        for _, key in ipairs(key_list) do
            if user_rocks[key] and not installed_rocks[key] then
                table.insert(to_install, key)
            elseif
                user_rocks[key]
                and installed_rocks[key]
                and user_rocks[key].version ~= installed_rocks[key].version
            then
                table.insert(to_updowngrade, key)
            elseif not user_rocks[key] and installed_rocks[key] then
                table.insert(to_prune, key)
            end
        end

        local ct = 1
        local action_count = #to_install + #to_updowngrade + #to_prune

        local function get_progress_percentage()
            return math.floor((ct / action_count) * 100)
        end

        for _, key in ipairs(to_install) do
            nio.scheduler()
            progress_handle:report({
                message = ("Installing: %s"):format(key),
            })
            -- If the plugin version is a development release then we pass `dev` as the version to the install function
            -- as it gets converted to the `--dev` flag on there, allowing luarocks to pull the `scm-1` rockspec manifest
            local future
            if vim.startswith(user_rocks[key].version, "scm-") then
                future = operations.install(user_rocks[key].name, "dev")
            else
                future = operations.install(user_rocks[key].name, user_rocks[key].version)
            end
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
        end
        for _, key in ipairs(to_updowngrade) do
            local is_downgrading = vim.version.parse(user_rocks[key].version)
                < vim.version.parse(installed_rocks[key].version)

            nio.scheduler()
            progress_handle:report({
                message = is_downgrading and ("Downgrading: %s"):format(key) or ("Updating: %s"):format(key),
            })

            local future = operations.install(user_rocks[key].name, user_rocks[key].version)
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

            local success = operations.remove_recursive(installed_rocks[key].name, user_rock_names)

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
    end)
end

--- Attempts to update every available rock if it is not pinned.
--- This function invokes a UI.
operations.update = function()
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
        local outdated_rocks = state.outdated_rocks()

        nio.scheduler()

        local user_rocks = parse_user_rocks()

        local progress_handle = progress.handle.create({
            title = "Updating",
            lsp_client = { name = constants.ROCKS_NVIM },
            percentage = 0,
        })

        local ct = 0
        for name, rock in pairs(outdated_rocks) do
            nio.scheduler()
            progress_handle:report({
                message = name,
            })
            local future = operations.install(name, rock.target_version)
            local success, ret = pcall(future.wait)
            ct = ct + 1
            nio.scheduler()
            if not success then
                report_error(("Failed to update %s."):format(rock.name))
                progress_handle:report({
                    percentage = math.floor((ct / #outdated_rocks) * 100),
                })
            end
            user_rocks.plugins[ret.name] = ret.version
            progress_handle:report({
                message = ("Updated %s: %s -> %s"):format(rock.name, rock.version, rock.target_version),
                percentage = math.floor((ct / #outdated_rocks) * 100),
            })
        end

        if vim.tbl_isempty(outdated_rocks) then
            nio.scheduler()
            progress_handle:report({ message = "Nothing to update!", percentage = 100 })
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
    end)
end

--- Adds a new rock and updates the `rocks.toml` file
---@param rock_name string #The rock name
---@param version? string #The version of the rock to use
operations.add = function(rock_name, version)
    local progress_handle = progress.handle.create({
        title = "Installing",
        message = version and ("%s -> %s"):format(rock_name, version) or rock_name,
        lsp_client = { name = constants.ROCKS_NVIM },
    })

    nio.run(function()
        local future = operations.install(rock_name, version)
        local success, installed_rock = pcall(future.wait)
        vim.schedule(function()
            if not success then
                progress_handle:report({
                    title = "Error",
                    message = ("Installation of %s failed"):format(rock_name),
                })
                progress_handle:cancel()
                return
            end
            progress_handle:report({
                title = "Installation successful",
                message = ("%s -> %s"):format(installed_rock.name, installed_rock.version),
                percentage = 100,
            })
            local user_rocks = parse_user_rocks()
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
            user_rocks.plugins[installed_rock.name] = installed_rock.version
            fs.write_file(config.config_path, "w", tostring(user_rocks))
            if success then
                progress_handle:finish()
            else
                progress_handle:cancel()
            end
        end)
        cache.populate_removable_rock_cache()
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
        local user_config = parse_user_rocks()
        if user_config.plugins then
            user_config.plugins[rock_name] = nil
        end
        if user_config.rocks then
            user_config.rocks[rock_name] = nil
        end
        local user_rock_names =
            ---@diagnostic disable-next-line: invisible
            nio.fn.keys(vim.tbl_deep_extend("force", user_config.rocks or {}, user_config.plugins or {}))
        local success = operations.remove_recursive(rock_name, user_rock_names, progress_handle)
        vim.schedule(function()
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
