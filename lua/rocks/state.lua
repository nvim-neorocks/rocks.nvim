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
local constants = require("rocks.constants")
local log = require("rocks.log")
local nio = require("nio")

---@type async fun(): {[string]: Rock}
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

---@type async fun(): {[string]: OutdatedRock}
state.outdated_rocks = nio.create(function()
    local rocks = vim.empty_dict()
    ---@cast rocks {[string]: Rock}

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
    end, { text = true, servers = constants.ALL_SERVERS })

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

return state
