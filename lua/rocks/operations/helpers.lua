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
local lock = require("rocks.operations.lock")
local constants = require("rocks.constants")
local config = require("rocks.config.internal")
local fs = require("rocks.fs")
local runtime = require("rocks.runtime")
local adapter = require("rocks.adapter")
local state = require("rocks.state")
local log = require("rocks.log")
local cache = require("rocks.cache")
local nio = require("nio")

local helpers = {}

helpers.semaphore = nio.control.semaphore(1)

---Decode the user rocks from rocks.toml, creating a default config file if it does not exist
---@return MutRocksTomlRef
function helpers.parse_rocks_toml()
    local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
    return require("toml_edit").parse(config_file)
end

---@param rocks_toml MutRocksTomlRef
---@param rock_name rock_name
---@return "plugins"|"rocks"|nil rocks_key The key of the table containing the rock entry
---@return rock_config_table|nil
function helpers.get_rock_and_key(rocks_toml, rock_name)
    local rocks_key = (rocks_toml.plugins and rocks_toml.plugins[rock_name] and "plugins")
        or (rocks_toml.rocks and rocks_toml.rocks[rock_name] and "rocks")
    return rocks_key, rocks_key and rocks_toml[rocks_key][rock_name]
end

---@class rocks.helpers.InstallOpts
---@field use_lockfile boolean

---@param rock_spec RockSpec
---@param opts? rocks.helpers.InstallOpts
---@return nio.control.Future
helpers.install = nio.create(function(rock_spec, opts)
    opts = opts or {}
    cache.invalidate_removable_rocks()
    local name = rock_spec.name:lower()
    local version = rock_spec.version
    local message = version and ("Installing: %s -> %s"):format(name, version) or ("Installing: %s"):format(name)
    log.info(message)
    -- TODO(vhyrro): Input checking on name and version
    local future = nio.control.future()
    local install_cmd = {
        "install",
        name,
    }
    local servers = {}
    vim.list_extend(servers, constants.ROCKS_SERVERS)
    if version then
        -- If specified version is dev then install the `scm-1` version of the rock
        if version == "dev" or version == "scm" then
            if cache.search_binary_dev_rocks(rock_spec.name, version) then
                -- Rock found on rocks-binaries-dev
                table.insert(servers, constants.ROCKS_BINARIES_DEV)
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
    local install_opts = {
        servers = servers,
    }
    if opts.use_lockfile then
        -- luarocks locks dependencies when there is a lockfile in the cwd
        local lockfile = lock.create_luarocks_lock(rock_spec.name)
        if lockfile and vim.uv.fs_stat(lockfile) then
            install_opts.cwd = vim.fs.dirname(lockfile)
        end
    end
    -- We always want to insert --pin so that the luarocks.lock is created in the
    -- install directory on the rtp
    table.insert(install_cmd, "--pin")
    luarocks.cli(install_cmd, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code ~= 0 then
            message = ("Failed to install %s"):format(name)
            log.error(message)
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

            nio.run(function()
                adapter.init_site_symlinks()
                if config.dynamic_rtp and not rock_spec.opt then
                    nio.scheduler()
                    runtime.packadd(name)
                else
                    -- Add rock to the rtp, but don't source any scripts
                    runtime.packadd(name, { bang = true })
                end
                future.set(installed_rock)
            end)
        end
    end, install_opts)
    return future
end, 2)

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
            adapter.validate_site_symlinks()
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
---@type async fun(name: string, keep: string[], progress_handle?: ProgressHandle): boolean
helpers.remove_recursive = nio.create(function(name, keep, progress_handle)
    ---@cast name string
    local dependencies = state.rock_dependencies(name)
    local future = helpers.remove(name, progress_handle)
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
            success = success and helpers.remove_recursive(dep.name, keep, progress_handle)
        end
    end
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

return helpers
