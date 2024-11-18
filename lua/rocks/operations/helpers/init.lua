---@mod rocks.operations.helpers
--
-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    07 Mar 2024
-- Updated:    19 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- This module has helpers (used by the rocks.operations modules), which interact with
-- luarocks. Installing, uninstalling, updating, etc.
--
---@brief ]]

local luarocks = require("rocks.luarocks")
local constants = require("rocks.constants")
local config = require("rocks.config.internal")
local fs = require("rocks.fs")
local runtime = require("rocks.runtime")
local state = require("rocks.state")
local log = require("rocks.log")
local cache = require("rocks.cache")
local nio = require("nio")
local multi_mut_rocks_toml_wrapper = require("rocks.operations.helpers.multi_mut_rocks_toml_wrapper")

local helpers = {}

helpers.semaphore = nio.control.semaphore(1)

---Decode the user rocks from rocks.toml, creating a default config file if it does not exist.
---A config path can be provided to only the return the config for a specific file. This path can
---be relative to the config_path directory or absolute with path expansion supported.
---@param config_path? string
---@return MultiMutRocksTomlWrapper
function helpers.parse_rocks_toml(config_path)
    if config_path then
        local absolute_config_path = fs.get_absolute_path(vim.fs.dirname(config.config_path), config_path)
        local base_rocks_toml =
            require("toml_edit").parse(fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG))
        -- Check to see if the path provided was the base config path, if so, just return that
        if absolute_config_path == config.config_path then
            return multi_mut_rocks_toml_wrapper.new({ { config = base_rocks_toml, path = config.config_path } })
        end

        -- For non-base configs, add it to the list of imports in the base config and write async
        if base_rocks_toml.import then
            local i = 0
            local import_path
            repeat
                i = i + 1
                import_path = base_rocks_toml.import[i]
            until import_path == nil or import_path == config_path
            base_rocks_toml.import[i] = config_path
        else
            base_rocks_toml.import = { config_path }
        end
        fs.write_file(config.config_path, "w", tostring(base_rocks_toml))

        return multi_mut_rocks_toml_wrapper.new({
            {
                config = require("toml_edit").parse(fs.read_or_create(absolute_config_path, "")),
                path = absolute_config_path,
            },
        })
    end

    local rocks_toml_configs = {}
    config.read_rocks_toml(function(file_str)
        -- Parse
        return require("toml_edit").parse(file_str)
    end, function(rocks_toml, file_path)
        -- Append to config list in order of preference returned by the read function
        table.insert(rocks_toml_configs, { config = rocks_toml, path = file_path })
    end)

    return multi_mut_rocks_toml_wrapper.new(rocks_toml_configs)
end

---@overload fun(rocks_toml: MultiMutRocksTomlWrapper, rock_name: rock_name): "plugins"|"rocks"|nil
---@overload fun(rocks_toml: MultiMutRocksTomlWrapper, rock_name: rock_name): rock_config_table|nil
---@param rocks_toml MutRocksTomlRef
---@param rock_name rock_name
---@return "plugins"|"rocks"|nil rocks_key The key of the table containing the rock entry
---@return rock_config_table|nil
function helpers.get_rock_and_key(rocks_toml, rock_name)
    local rocks_key = (rocks_toml.plugins and rocks_toml.plugins[rock_name] and "plugins")
        or (rocks_toml.rocks and rocks_toml.rocks[rock_name] and "rocks")
    return rocks_key, rocks_key and rocks_toml[rocks_key][rock_name]
end

---@param rock_spec RockSpec
---@param progress_handle? ProgressHandle
---@return nio.control.Future
helpers.install = nio.create(function(rock_spec, progress_handle)
    cache.invalidate_removable_rocks()
    rock_spec.name = rock_spec.name:lower()
    local name = rock_spec.name
    local version = rock_spec.version
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
    local servers = {}
    vim.list_extend(servers, config.get_servers())
    if version then
        -- If specified version is dev then install the `scm-1` version of the rock
        if version == "dev" or version == "scm" then
            if cache.search_binary_dev_rocks(rock_spec.name, version) then
                -- Rock found on rocks-binaries-dev
                vim.list_extend(servers, config.get_dev_servers())
            else
                -- Search dev manifest
                table.insert(install_cmd, 2, "--dev")
            end
        else
            table.insert(install_cmd, version)
        end
    end
    ---@param install_arg string
    vim.iter(rock_spec.install_args or {}):each(function(install_arg)
        table.insert(install_cmd, install_arg)
    end)
    table.insert(install_cmd, 2, "--force")
    luarocks.cli(install_cmd, function(sc)
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
            vim.schedule(function()
                vim.api.nvim_exec_autocmds("User", {
                    pattern = "RocksInstallPost",
                    modeline = false,
                    ---@type rocks.user-events.data.RocksInstallPost
                    data = {
                        spec = rock_spec,
                        installed = installed_rock,
                    },
                })
            end)
            message = ("Installed: %s -> %s"):format(installed_rock.name, installed_rock.version)
            log.info(message)
            if progress_handle then
                progress_handle:report({ message = message })
            end

            future.set(installed_rock)
        end
    end, {
        servers = servers,
    })
    return future
end, 2)

---Dynamically load a rock (asynchronously) if the `dynamic_rtp` option is enabled
---Sources non-`opt` rocks' plugin scripts
---and adds `opt` rocks to the runtimepath.
---@param rock_spec RockSpec
---@return nio.control.Future
function helpers.dynamic_load(rock_spec)
    local future = nio.control.future()
    if not config.dynamic_rtp then
        log.trace("Dynamic rtp is disabled.")
        future.set(true)
        return future
    end
    nio.run(function()
        vim.schedule(function()
            pcall(function()
                if rock_spec.opt then
                    -- Add rock to the rtp, but don't source any scripts
                    log.trace(("Adding %s to the runtimepath"):format(rock_spec.name))
                    runtime.packadd(rock_spec, { bang = true })
                else
                    log.trace(("Sourcing %s"):format(rock_spec.name))
                    runtime.packadd(rock_spec)
                end
            end)
            future.set(true)
        end)
    end)
    return future
end

---Removes a rock
---@param name string
---@param progress_handle? ProgressHandle
---@return nio.control.Future
helpers.remove = function(name, progress_handle)
    cache.invalidate_removable_rocks()
    local message = ("Uninstalling: %s"):format(name)
    log.info(message)
    if progress_handle then
        progress_handle:report({ message = message })
    end
    local future = nio.control.future()
    luarocks.cli({
        "remove",
        name,
    }, function(sc)
        nio.run(function()
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
    end)
    return future
end

---Removes a rock, and recursively removes its dependencies
---if they are no longer needed.
---@type async fun(name: string, keep?: string[], progress_handle?: ProgressHandle): boolean
helpers.remove_recursive = nio.create(function(name, keep, progress_handle)
    ---@diagnostic disable-next-line: invisible
    keep = keep or nio.fn.keys(config.get_user_rocks())
    ---@cast name string
    local dependencies = state.rock_dependencies(name)
    local future = helpers.remove(name, progress_handle)
    local success, _ = pcall(future.wait)
    if not success then
        return false
    end
    local removable_rocks = state.query_removable_rocks()
    ---@type rock_name[]
    local removable_dependencies = vim.iter(dependencies):fold({}, function(acc, rock_name)
        if vim.list_contains(removable_rocks, rock_name) and not vim.list_contains(keep, rock_name) then
            table.insert(acc, rock_name)
        end
        return acc
    end)
    success = vim.iter(removable_dependencies):fold(
        true,
        ---@param acc boolean
        ---@param dep rock_name
        function(acc, dep)
            if vim.list_contains(removable_rocks, dep) then
                acc = acc and helpers.remove_recursive(dep, keep, progress_handle)
            end
            return acc
        end
    )
    return success
end, 3)

---@async
---@param rock_name rock_name
---@return boolean
helpers.is_installed = nio.create(function(rock_name)
    local future = nio.control.future()
    ---@param sc vim.SystemCompleted
    luarocks.cli({ "show", rock_name }, function(sc)
        future.set(sc.code == 0)
    end)
    return future.wait()
end, 1)

---@param rock OutdatedRock
---@return RockUpdate | nil
local function get_breaking_change(rock)
    local _, version = pcall(vim.version.parse, rock.version)
    local _, target_version = pcall(vim.version.parse, rock.target_version)
    if type(version) == "table" and type(target_version) == "table" and target_version.major > version.major then
        return setmetatable({
            name = rock.name,
            version = version,
            target_version = target_version,
        }, {
            __tostring = function()
                return ("%s %s -> %s"):format(rock.name, tostring(version), tostring(target_version))
            end,
        })
    end
end

---@type fun(rock_name: rock_name): RockUpdate | nil
helpers.get_breaking_change = nio.create(function(rock_name)
    local rock = state.outdated_rocks()[rock_name]
    return rock and get_breaking_change(rock)
end, 2)

---@class RockUpdate
---@field name rock_name
---@field version vim.Version
---@field target_version vim.Version
---@field pretty string

---@param outdated_rocks table<rock_name, OutdatedRock>
---@return table<rock_name, RockUpdate[]>
function helpers.get_breaking_changes(outdated_rocks)
    return vim.iter(outdated_rocks):fold(
        {},
        ---@param acc table<rock_name, RockUpdate>
        ---@param key rock_name
        ---@param rock OutdatedRock
        function(acc, key, rock)
            local breaking_change = get_breaking_change(rock)
            if breaking_change then
                acc[key] = breaking_change
            end
            return acc
        end
    )
end

---@type async fun(rock: RockUpdate): boolean
helpers.prompt_for_breaking_intall = nio.create(function(rock)
    local prompt = ([[
%s may be a breaking change! Update anyway?
To skip this prompt, run 'Rocks! install {rock}'
]]):format(tostring(rock))
    nio.scheduler()
    local choice = vim.fn.confirm(prompt, "&Yes\n&No", 2, "Question")
    return choice == 1
end, 1)

---@type async fun(breaking_changes: table<rock_name, RockUpdate>, outdated_rocks: table<rock_name, OutdatedRock>): table<rock_name, OutdatedRock>
helpers.prompt_for_breaking_update = nio.create(function(breaking_changes, outdated_rocks)
    local pretty_changes = vim.iter(breaking_changes)
        :map(function(_, breaking_change)
            return tostring(breaking_change)
        end)
        :totable()
    local prompt = ([[
There are potential breaking changes! Update them anyway?
To skip this prompt, run 'Rocks! update'

Breaking changes:
%s
]]):format(table.concat(pretty_changes, "\n"))
    nio.scheduler()
    local choice = vim.fn.confirm(prompt, "&Yes\n&No", 2, "Question")
    if choice == 1 then
        return outdated_rocks
    end
    return vim.iter(outdated_rocks):fold(
        {},
        ---@param acc table<rock_name, OutdatedRock>
        ---@param key rock_name
        ---@param rock OutdatedRock
        function(acc, key, rock)
            if not breaking_changes[key] then
                acc[key] = rock
            end
            return acc
        end
    )
end, 2)

--- Post-install actions
function helpers.postInstall()
    if config.update_remote_plugins and type(vim.cmd.UpdateRemotePlugins) == "function" then
        pcall(vim.cmd.UpdateRemotePlugins)
    end
    -- Re-generate help tags
    if config.generate_help_pages then
        vim.cmd.helptags("ALL")
    end
end

---Installs or removes a rock stub so that luarocks will recognise rocks installed by
---extensions like rocks-git and rocks-dev as dependencies
---@param opts rock_handler.on_success.Opts
helpers.manage_rock_stub = nio.create(function(opts)
    if not config.experimental_features.ext_module_dependency_stubs then
        log.debug("Installing stubs is disabled")
        return
    end
    if opts.action == "install" then
        local rock = opts.rock
        log.info(("Installing stub %s"):format(vim.inspect(rock)))
        local rockspec_content = constants.STUB_ROCKSPEC_TEMPLATE:format(
            rock.name,
            rock.version,
            opts.dependencies and vim.inspect(opts.dependencies) or "{}"
        )
        nio.scheduler()
        local tempdir = vim.fn.tempname()
        local ok = fs.mkdir_p(tempdir)
        if not ok then
            log.error(("Could not create temp directory for rock stub %s rockspec"):format(vim.inspect(rock)))
            return
        end
        local rockspec_file = ("%s-%s-1.rockspec"):format(rock.name, rock.version)
        local rockspec_path = vim.fs.joinpath(tempdir, rockspec_file)
        fs.write_file_await(rockspec_path, "w", rockspec_content)
        -- XXX For now, we ignore failures and only log them
        local future = nio.control.future()
        luarocks.cli(
            { "install", rockspec_file },
            ---@param sc vim.SystemCompleted
            function(sc)
                if sc.code ~= 0 then
                    log.error(("Failed to install stub from rockspec %s"):format(rockspec_path))
                end
                future.set(true)
            end,
            { cwd = tempdir }
        )
        future.wait()
    elseif opts.action == "prune" then
        helpers.remove_recursive(opts.rock.name)
    end
end)

return helpers
