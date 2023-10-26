---@mod rocks.search luarocks search
---
---@brief [[
---
--- Search for luarocks packages
---
---@brief ]]
---
---
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    25 Oct 2023
-- Updated:    25 Oct 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>

local search = {}

local luarocks = require("rocks.luarocks")
local nio = require("nio")

---@type Rock[] | nil
local _cache = nil

---@async
local populate_cache = nio.create(function()
    if _cache then
        return
    end
    _cache = {}
    local future = nio.control.future()
    luarocks.cli({ "search", "--porcelain", "--all" }, function(obj)
        ---@cast obj vim.SystemCompleted
        future.set(obj)
    end, { text = true })
    ---@type vim.SystemCompleted
    local obj = future.wait()
    local result = obj.stdout
    if obj.code ~= 0 or not result then
        -- set cache back to nil so that we can retry again
        _cache = nil
        return
    end
    for name, version in result:gmatch("([^%s]+)%s+(%d+%.%d+%.%d+%-%d+)%s+") do
        table.insert(_cache, { name = name, version = version })
    end
    if #_cache == 0 then
        _cache = nil
    end
end)

---@param name string
---@param query string | nil
---@return string[]
search.complete_versions = function(name, query)
    if not _cache then
        nio.run(populate_cache)
        return {}
    end
    local matching_rocks = vim.tbl_filter(function(rock)
        ---@cast rock Rock
        if not query then
            return rock.name == name
        end
        return rock.name == name and vim.startswith(rock.version, query)
    end, _cache)
    local unique_versions = {}
    for _, rock in pairs(matching_rocks) do
        unique_versions[rock.version] = rock
    end
    return vim.tbl_keys(unique_versions)
end

---@param query string | nil
---@return string[]
search.complete_names = function(query)
    if not _cache then
        nio.run(populate_cache)
        return {}
    end
    if not query then
        return {}
    end
    local matching_rocks = vim.tbl_filter(function(rock)
        ---@cast rock Rock
        return vim.startswith(rock.name, query)
    end, _cache)
    ---@type {[string]: Rock}
    local unique_rocks = {}
    for _, rock in pairs(matching_rocks) do
        unique_rocks[rock.name] = rock
    end
    return vim.tbl_keys(unique_rocks)
end

return search
