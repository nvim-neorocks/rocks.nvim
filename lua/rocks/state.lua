---@mod rocks.state
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    19 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>
--
---@brief [[
--
-- Functions for keeping track of the state of installed packages.
--
---@brief ]]

local state = {}

---Used for completions only
---@type string[] | nil
local _removable_rock_cache = nil

local luarocks = require("rocks.luarocks")
local fzy = require("rocks.fzy")
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
        -- Exclude -<specrev>
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
    end, { text = true })

    local installed_rock_list = future.wait()

    for name, version, target_version in installed_rock_list:gmatch("(%S+)%s+(%S+)%s+(%S+)%s+%S+") do
        rocks[name] = { name = name, version = version, target_version = target_version }
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
        "--deps",
        "--porcelain",
        rock_name,
    }, function(obj)
        if obj.code ~= 0 then
            future.set_error(("Could not get dependencies for rock %s: %s"):format(rock_name, obj.stderr))
        else
            future.set(obj.stdout)
        end
    end, { text = true })

    local success, result = pcall(future.wait)
    if not success then
        -- TODO: Log error
        return {}
    end

    for line in string.gmatch(result, "%S*[^\n]+") do
        local name, version = line:match("(%S+)%s%S+%s(%S+)")
        if not name then
            name = line:match("(%S+)")
        end
        if name and name ~= "lua" then
            dependencies[name] = { name = name, version = version }
        end
    end

    return dependencies
end)

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
            dependent_rocks[#dependent_rocks + 1] = dep.name
        end
    end
    ---@diagnostic disable-next-line: invisible
    return vim.iter(nio.fn.keys(installed_rocks))
        :filter(function(rock_name)
            return rock_name ~= "rocks.nvim" and not vim.list_contains(dependent_rocks, rock_name)
        end)
        :totable()
end)

---@type async fun()
local populate_removable_rock_cache = nio.create(function()
    if _removable_rock_cache then
        return
    end
    _removable_rock_cache = state.query_removable_rocks()
end)

---Completion for installed rocks that are not dependencies of other rocks
---and can be removed.
---@param query string | nil
---@return string[]
state.complete_removable_rocks = function(query)
    if not _removable_rock_cache then
        nio.run(populate_removable_rock_cache)
        return {}
    end
    if not query then
        return {}
    end
    return fzy.fuzzy_filter(query, _removable_rock_cache)
end

state.invalidate_cache = function()
    _removable_rock_cache = nil
end

return state
