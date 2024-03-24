---@mod rocks.cache rocks.nvim luarocks cache
---
---@brief [[
---
---Cached luarocks state.
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    07 Dec 2023
-- Updated:    07 Dec 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

local cache = {}

local luarocks = require("rocks.luarocks")
local state = require("rocks.state")
local constants = require("rocks.constants")
local nio = require("nio")

---@type { [rock_name]: Rock[] } | nil
local _cached_rocks = nil

---@type { [rock_name]: Rock[] } | nil
local _cached_dev_binaries = nil

---Used for completions only
---@type string[] | nil
local _removable_rock_cache = nil

---Query luarocks packages and populate the cache.
---@type async fun()
cache.populate_cached_rocks = nio.create(function()
    if _cached_rocks then
        return
    end
    luarocks.search_all(function(rocks)
        if not vim.tbl_isempty(rocks) then
            _cached_rocks = rocks
        end
    end, {
        dev = true,
    })
end)

---Tries to get the cached rocks.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@return { [string]: Rock[] } rocks indexed by name
function cache.try_get_rocks()
    if not _cached_rocks then
        nio.run(cache.populate_cached_rocks)
        local rocks = vim.empty_dict()
        ---@cast rocks { [string]: Rock[] }
        return rocks
    end
    return _cached_rocks
end

---Query the state for rocks that can be removed
---and populate the cache.
---@type async fun()
cache.populate_removable_rock_cache = nio.create(function()
    if _removable_rock_cache then
        return
    end
    _removable_rock_cache = state.query_removable_rocks()
end)

---Tries to get the cached removable rocks.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@return { [string]: Rock[] } rocks indexed by name
function cache.try_get_removable_rocks()
    if not _removable_rock_cache then
        nio.run(cache.populate_removable_rock_cache)
        local rocks = vim.empty_dict()
        ---@cast rocks { [string]: Rock[] }
        return rocks
    end
    return _removable_rock_cache
end

---Invalidate the removable rocks cache
cache.invalidate_removable_rocks = function()
    _removable_rock_cache = nil
end

---Search the cache for rocks-binaries-dev rocks.
---Repopulates the cache and runs a second search if not found
---@type async fun(rock_name: string, version: string?)
cache.search_binary_dev_rocks = nio.create(function(rock_name, version)
    ---@cast rock_name rock_name
    ---@cast version string
    local function search_cache()
        local rocks
        if _cached_dev_binaries then
            rocks = _cached_dev_binaries[rock_name]
        end
        return rocks
            and vim.iter(rocks):any(function(rock)
                ---@cast rock Rock
                if version == "dev" then
                    version = "scm"
                end
                return not version or rock.version == version
            end)
    end
    local found = search_cache()
    if found then
        return found
    end
    local future = nio.control.future()
    luarocks.search_all(function(result)
        if not vim.tbl_isempty(result) then
            _cached_dev_binaries = result
        end
        future.set(true)
    end, {
        servers = constants.ROCKS_BINARIES_DEV,
    })
    future.wait()
    return search_cache()
end, 2)

return cache
