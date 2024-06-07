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
local parser = require("rocks.operations.parser")
local nio = require("nio")
local progress = require("fidget.progress")

local operations = {}

local semaphore = nio.control.semaphore(1)

operations.register_handler = handlers.register_handler

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

---@param outdated_rocks table<rock_name, OutdatedRock>
---@return table<rock_name, OutdatedRock>
local function add_dev_rocks_for_update(outdated_rocks)
    return vim.iter(config.get_user_rocks()):fold(outdated_rocks, function(acc, name, spec)
        ---@cast acc table<rock_name, OutdatedRock>
        ---@cast name rock_name
        ---@cast spec RockSpec
        if spec.version == "scm" then
            acc[name] = {
                name = spec.name,
                version = spec.version,
                target_version = spec.version,
            }
        end
        return acc
    end)
end

---@param rocks_toml MutRocksTomlRef
---@param rock_name rock_name
---@return "plugins"|"rocks"|nil rocks_key The key of the table containing the rock entry
---@return rock_config_table|nil
local function get_rock_and_key(rocks_toml, rock_name)
    local rocks_key = (rocks_toml.plugins and rocks_toml.plugins[rock_name] and "plugins")
        or (rocks_toml.rocks and rocks_toml.rocks[rock_name] and "rocks")
    return rocks_key, rocks_key and rocks_toml[rocks_key][rock_name]
end

--- Synchronizes the user rocks with the physical state on the current machine.
--- - Installs missing rocks
--- - Ensures that the correct versions are installed
--- - Uninstalls unneeded rocks
---@param user_rocks? table<rock_name, RockSpec|string> loaded from rocks.toml if `nil`
---@param on_complete? function
operations.sync = function(user_rocks, on_complete)
    log.info("syncing...")
    nio.run(function()
        semaphore.with(function()
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

            ---@class SyncSkippedRock
            ---@field spec RockSpec
            ---@field reason string

            ---@type SyncSkippedRock[]
            local skipped_rocks = {}

            for _, key in ipairs(to_install) do
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
            for _, callback in ipairs(external_actions) do
                ct = ct + 1
                callback(report_progress, report_error)
            end

            -- rocks.nvim sync handlers should be installed now.
            -- try installing any rocks that rocks.nvim could not handle itself
            for _, skipped_rock in ipairs(skipped_rocks) do
                local spec = skipped_rock.spec
                ct = ct + 1
                local callback = handlers.get_sync_handler_callback(spec)
                if callback then
                    callback(report_progress, report_error)
                else
                    report_error(("Failed to install %s: %s"):format(spec.name, skipped_rock.reason))
                end
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
                to_prune = vim.empty_dict()
                installed_rocks = state.installed_rocks()
                key_list = nio.fn.keys(vim.tbl_deep_extend("force", installed_rocks, user_rocks))
                ---@cast to_prune string[]
                for _, key in ipairs(key_list) do
                    if not user_rocks[key] and installed_rocks[key] then
                        table.insert(to_prune, key)
                    end
                end
                local dependencies = vim.empty_dict()
                ---@cast dependencies {[string]: RockDependency}
                for _, installed_rock in pairs(installed_rocks) do
                    for k, v in pairs(state.rock_dependencies(installed_rock)) do
                        dependencies[k] = v
                    end
                end

                prunable_rocks = vim.iter(to_prune)
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

            -- Re-generate help tags
            if config.generate_help_pages then
                vim.cmd("helptags ALL")
            end
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

--- Attempts to update every available rock if it is not pinned.
--- This function invokes a UI.
---@param on_complete? function
operations.update = function(on_complete)
    local progress_handle = progress.handle.create({
        title = "Updating",
        message = "Checking for updates...",
        lsp_client = { name = constants.ROCKS_NVIM },
        percentage = 0,
    })

    nio.run(function()
        semaphore.with(function()
            ---@type ProgressHandle[]
            local error_handles = {}
            ---@param message string
            local function report_error(message)
                log.error(("UPDATE ERROR: %s"):format(message))
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
            if config.reinstall_dev_rocks_on_update then
                outdated_rocks = add_dev_rocks_for_update(outdated_rocks)
            end
            local external_update_handlers = handlers.get_update_handler_callbacks(user_rocks)

            local total_update_count = #outdated_rocks + #external_update_handlers

            nio.scheduler()

            local ct = 0
            for name, rock in pairs(outdated_rocks) do
                local rocks_key, user_rock = get_rock_and_key(user_rocks, rock.name)
                if not user_rock or user_rock.pin then
                    goto skip_update
                end
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
                    if user_rock and user_rock.version then
                        -- Rock is configured as a table -> Update version.
                        user_rocks[rocks_key][rock_name].version = ret.version
                    elseif user_rock then -- Only insert the version if there's an entry in rocks.toml
                        user_rocks[rocks_key][rock_name] = ret.version
                    end
                    progress_handle:report({
                        message = rock.version == rock.target_version
                                and ("Updated rock %s: %s"):format(rock.name, rock.version)
                            or ("Updated %s: %s -> %s"):format(rock.name, rock.version, rock.target_version),
                        percentage = get_percentage(ct, total_update_count),
                    })
                else
                    report_error(("Failed to update %s."):format(rock.name))
                    progress_handle:report({
                        percentage = get_percentage(ct, total_update_count),
                    })
                end
                ::skip_update::
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
                fs.write_file_await(config.config_path, "w", tostring(user_rocks))
            end
            nio.scheduler()
            if not vim.tbl_isempty(error_handles) then
                local message = "Update completed with errors! Run ':Rocks log' for details."
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
            if on_complete then
                on_complete()
            end
        end)
    end)
end

--- Prompt to retry an installation searching the dev manifest, if the version
--- is not "dev" or "scm"
---@param arg_list string[] #Argument list, potentially used by external handlers
---@param rock_name rock_name #The rock name
---@param version? string #The version of the rock to use
local function prompt_retry_install_with_dev(arg_list, rock_name, version)
    if version ~= "dev" then
        vim.schedule(function()
            local choice =
                vim.fn.confirm("Could not find " .. rock_name .. ". Search for 'dev' version?", "y/n", "y", "Question")
            if choice == 1 then
                arg_list = vim.iter(arg_list)
                    :filter(function(arg)
                        -- remove rock_name and version from arg_list
                        return arg:find("=") ~= nil and not vim.startswith(arg, "version=")
                    end)
                    :totable()
                table.insert(arg_list, 1, "dev")
                table.insert(arg_list, 1, rock_name)
                nio.run(function()
                    operations.add(arg_list)
                end)
            end
        end)
    end
end

--- Adds a new rock and updates the `rocks.toml` file
---@param arg_list string[] #Argument list, potentially used by external handlers. The first argument is the package, e.g. the rock name
---@param callback? fun(rock: Rock)
operations.add = function(arg_list, callback)
    local progress_handle = progress.handle.create({
        title = "Installing",
        lsp_client = { name = constants.ROCKS_NVIM },
    })
    local function report_error(message)
        log.error(("INSTALL ERROR: %s"):format(message))
        progress_handle:report({
            title = "Error",
            message = message,
        })
        progress_handle:cancel()
    end

    nio.run(function()
        semaphore.with(function()
            local user_rocks = parse_rocks_toml()
            local handler = handlers.get_install_handler_callback(user_rocks, arg_list)
            if type(handler) == "function" then
                local function report_progress(message)
                    progress_handle:report({
                        message = message,
                    })
                end
                handler(report_progress, report_error)
                fs.write_file_await(config.config_path, "w", tostring(user_rocks))
                nio.scheduler()
                progress_handle:finish()
                return
            end
            ---@type rock_name
            local rock_name = arg_list[1]:lower()
            -- We can't mutate the arg_list, because we may need it for a recursive add
            ---@type string[]
            local args = #arg_list == 1 and {} or { unpack(arg_list, 2, #arg_list) }
            local parse_result = parser.parse_install_args(args)
            if not vim.tbl_isempty(parse_result.invalid_args) then
                report_error(("invalid install args: %s"):format(vim.inspect(parse_result.invalid_args)))
                return
            end
            if not vim.tbl_isempty(parse_result.conflicting_args) then
                report_error(("conflicting install args: %s"):format(vim.inspect(parse_result.conflicting_args)))
                return
            end
            local install_spec = parse_result.spec
            local version = install_spec.version
            nio.scheduler()
            progress_handle:report({
                message = version and ("%s -> %s"):format(rock_name, version) or rock_name,
            })
            local future = helpers.install({
                name = rock_name,
                version = version,
            })
            ---@type boolean, Rock | string
            local success, installed_rock = pcall(future.wait)
            if not success then
                local stderr = installed_rock
                ---@cast stderr string
                local not_found = stderr:match("No results matching query were found") ~= nil
                local message = ("Installation of %s failed. Run ':Rocks log' for details."):format(rock_name)
                if not_found then
                    message = ("Could not find %s %s"):format(rock_name, version or "")
                end
                nio.scheduler()
                progress_handle:report({
                    title = "Installation failed",
                    message = message,
                })
                if not_found then
                    prompt_retry_install_with_dev(arg_list, rock_name, version)
                end
                nio.scheduler()
                progress_handle:cancel()
                return
            end
            ---@cast installed_rock Rock
            nio.scheduler()
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

            -- Set installed version as `scm` if development version has been installed
            if version == "dev" then
                installed_rock.version = "scm"
            end
            local user_rock = user_rocks.plugins[rock_name]
            if user_rock and user_rock.version then
                -- Rock already exists in rock.toml and is configured as a table -> Update version.
                user_rocks.plugins[rock_name].version = installed_rock.version
                for _, field in ipairs({ "opt", "pin" }) do
                    if install_spec[field] then
                        user_rocks.plugins[rock_name][field] = true
                    elseif user_rocks.plugins[rock_name][field] then
                        user_rocks.plugins[rock_name][field] = nil
                    end
                end
            elseif install_spec.opt or install_spec.pin then
                -- toml-edit's metatable can't set a table directly.
                -- Each field has to be set individually.
                user_rocks.plugins[rock_name] = {}
                user_rocks.plugins[rock_name].version = installed_rock.version
                user_rocks.plugins[rock_name].opt = install_spec.opt
                user_rocks.plugins[rock_name].pin = install_spec.pin
            else
                user_rocks.plugins[rock_name] = installed_rock.version
            end
            fs.write_file_await(config.config_path, "w", tostring(user_rocks))
            cache.populate_removable_rock_cache()
            vim.schedule(function()
                -- Re-generate help tags
                if config.generate_help_pages then
                    vim.cmd("helptags ALL")
                end
                if success then
                    progress_handle:finish()
                    if callback then
                        callback(installed_rock)
                    end
                else
                    progress_handle:cancel()
                end
            end)
        end)
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
        semaphore.with(function()
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
            fs.write_file_await(config.config_path, "w", tostring(user_config))
            cache.populate_removable_rock_cache()
            vim.schedule(function()
                if success then
                    progress_handle:finish()
                else
                    local message = "Prune completed with errors! Run ':Rocks log' for details."
                    log.error(message)
                    progress_handle:report({
                        title = "Error",
                        message = message,
                    })
                    progress_handle:cancel()
                end
            end)
        end)
    end)
end

---@param rock_name rock_name
operations.pin = function(rock_name)
    nio.run(function()
        semaphore.with(function()
            local user_config = parse_rocks_toml()
            local rocks_key, user_rock = get_rock_and_key(user_config, rock_name)
            if not rocks_key then
                vim.schedule(function()
                    vim.notify(rock_name .. " not found in rocks.toml", vim.log.levels.ERROR)
                end)
                return
            end
            if type(user_rock) == "string" then
                local version = user_config[rocks_key][rock_name]
                user_config[rocks_key][rock_name] = {}
                user_config[rocks_key][rock_name].version = version
            end
            user_config[rocks_key][rock_name].pin = true
            local version = user_config[rocks_key][rock_name].version
            fs.write_file_await(config.config_path, "w", tostring(user_config))
            vim.schedule(function()
                vim.notify(("%s pinned to version %s"):format(rock_name, version), vim.log.levels.INFO)
            end)
        end)
    end)
end

---@param rock_name rock_name
operations.unpin = function(rock_name)
    nio.run(function()
        semaphore.with(function()
            local user_config = parse_rocks_toml()
            local rocks_key, user_rock = get_rock_and_key(user_config, rock_name)
            if not rocks_key or not user_rock then
                vim.schedule(function()
                    vim.notify(rock_name .. " not found in rocks.toml", vim.log.levels.ERROR)
                end)
                return
            end
            if type(user_rock) == "string" then
                return
            end
            if not user_rock.opt then
                user_config[rocks_key][rock_name] = user_config[rocks_key][rock_name].version
            else
                user_config[rocks_key][rock_name].pin = nil
            end
            fs.write_file_await(config.config_path, "w", tostring(user_config))
            vim.schedule(function()
                vim.notify(("%s unpinned"):format(rock_name), vim.log.levels.INFO)
            end)
        end)
    end)
end

return operations
