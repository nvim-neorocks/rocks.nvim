---@mod rocks.state
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    19 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- Functions for keeping track of the state of installed packages.
--
---@brief ]]

local state = {}

local luarocks = require("rocks.luarocks")
local config = require("rocks.config.internal")
local log = require("rocks.log")
local nio = require("nio")

---@type async fun(): table<rock_name, Rock>
state.installed_rocks = nio.create(function()
    local rocks = vim.empty_dict()
    ---@cast rocks {[string]: Rock}

    local future = nio.control.future()

    luarocks.cli({
        "list",
        "--porcelain",
    }, function(obj)
        if obj.code ~= 0 then
            future.set_error(obj.stderr)
        else
            future.set(obj.stdout)
        end
    end, { text = true })

    local installed_rock_list = future.wait()

    for name, version in installed_rock_list:gmatch("(%S+)%s+(%S+)%s+installed%s+%S+") do
        -- Exclude -<specrev> from version
        rocks[name] = { name = name, version = version:match("([^-]+)") }
    end

    return rocks
end)

---@type async fun(): table<rock_name, OutdatedRock>
state.outdated_rocks = nio.create(function()
    local rocks = vim.empty_dict() --[[ @as table<rock_name, OutdatedRock> ]]

    local future = nio.control.future()

    luarocks.cli({
        "list",
        "--porcelain",
        "--outdated",
    }, function(obj)
        if obj.code ~= 0 then
            future.set_error(obj.stderr)
        else
            future.set(obj.stdout)
        end
    end, { text = true, servers = config.get_servers() })

    local installed_rock_list = future.wait()

    for name, version, target_version in installed_rock_list:gmatch("(%S+)%s+(%S+)%s+(%S+)%s+%S+") do
        -- Exclude -<specrev> from versions
        rocks[name] = {
            name = name,
            version = version:match("([^-]+)"),
            target_version = target_version:match("([^-]+)"),
        }
    end

    return rocks
end)

---List the dependencies of an installed Rock
---@type async fun(rock:Rock|string): {[string]: RockDependency}
state.rock_dependencies = nio.create(function(rock)
    ---@cast rock Rock|string

    local dependencies = vim.empty_dict()
    ---@cast dependencies {[string]: RockDependency}

    local future = nio.control.future()

    ---@type string
    local rock_name = rock.name or rock

    luarocks.cli({
        "show",
        "--porcelain",
        rock_name,
    }, function(obj)
        if obj.code ~= 0 then
            local message = ("Could not get dependencies for rock %s: %s"):format(rock_name, obj.stderr)
            log.error(message)
            future.set_error(message)
        else
            future.set(obj.stdout)
        end
    end, { text = true })

    local success, result = pcall(future.wait)
    if not success then
        log.error(result)
        return {}
    end

    for line in string.gmatch(result, "%S*[^\n]+") do
        local name, version = line:match("dependency%s+(%S+).*using%s+([^-%s]+)")
        if not name then
            name = line:match("(%S+)")
        end
        if name and name ~= "lua" then
            dependencies[name] = { name = name, version = version }
        end
    end

    return dependencies
end, 1)

---List installed rocks that are not dependencies of any other rocks
---and can be removed.
---@type async fun(): string[]
state.query_removable_rocks = nio.create(function()
    local installed_rocks = state.installed_rocks()
    --- Unfortunately, luarocks can't list dependencies via its CLI.
    local dependent_rocks = vim.empty_dict()
    ---@cast dependent_rocks string[]
    for _, rock in pairs(installed_rocks) do
        for _, dep in pairs(state.rock_dependencies(rock)) do
            table.insert(dependent_rocks, dep.name)
        end
    end
    ---@diagnostic disable-next-line: invisible
    return vim.iter(nio.fn.keys(installed_rocks))
        :filter(function(rock_name)
            return rock_name ~= "rocks.nvim" and not vim.list_contains(dependent_rocks, rock_name)
        end)
        :totable()
end)

---@class rocks.state.SyncStatus
---@field external_actions table<rock_name, rock_handler_callback>
---@field to_install rock_name[]
---@field to_updowngrade rock_name[]
---@field to_prune rock_name[]

---@type async fun(user_rocks?: table<rock_name, RockSpec>): rocks.state.SyncStatus
state.out_of_sync_rocks = nio.create(function(user_rocks)
    local handlers = require("rocks.operations.handlers")
    user_rocks = user_rocks or config.get_user_rocks()
    local installed_rocks = state.installed_rocks()
    -- The following code uses `nio.fn.keys` instead of `vim.tbl_keys`
    -- which invokes the scheduler and works in async contexts.
    ---@type string[]
    ---@diagnostic disable-next-line: invisible
    local key_list = nio.fn.keys(vim.tbl_deep_extend("force", installed_rocks, user_rocks))
    ---@type rocks.state.SyncStatus
    local mempty = {
        external_actions = vim.empty_dict(),
        to_install = vim.empty_dict(),
        to_updowngrade = vim.empty_dict(),
        to_prune = vim.empty_dict(),
    }
    ---@param acc rocks.state.SyncStatus
    return vim.iter(key_list):fold(mempty, function(acc, key)
        local user_rock = user_rocks[key]
        local callback = user_rock and handlers.get_sync_handler_callback(user_rock)
        if callback then
            acc.external_actions[key] = callback
        elseif user_rocks and not installed_rocks[key] then
            table.insert(acc.to_install, key)
        elseif
            user_rock
            and user_rock.version
            and installed_rocks[key]
            and user_rock.version ~= installed_rocks[key].version
        then
            table.insert(acc.to_updowngrade, key)
        elseif not user_rock and installed_rocks[key] then
            table.insert(acc.to_prune, key)
        end
        return acc
    end)
end, 1)

return state
