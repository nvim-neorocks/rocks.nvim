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

---@type table<rock_name, Rock[]> | nil
local _cached_rocks = nil

---@type table<rock_name, Rock[]> | nil
local _cached_dev_binaries = nil

---Used for completions only
---@type string[] | nil
local _removable_rock_cache = nil

---@type table<rock_name, OutdatedRock> | nil
local _outdated_rock_cache = nil

---Tries to get the cached value
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---WARNING: `cache_ref` MUST be populated by `populate`
---
---@generic T
---@param cache_ref T
---@param populate async fun():T Function that populates the cache asynchronously
---@param populate_sync? fun():T Function that populates the cache synchronously
---@return table<string, T> result indexed by name
local function try_get_unsafe(cache_ref, populate, populate_sync)
    if not cache_ref then
        if type(populate_sync) == "function" then
            populate_sync()
            return cache_ref
        else
            nio.run(populate)
        end
        local result = vim.empty_dict()
        return result
    end
    return cache_ref
end

local function populate_cached_rocks_sync()
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
end

---Query luarocks packages and populate the cache.
---@type async fun()
cache.populate_cached_rocks = nio.create(populate_cached_rocks_sync)

---Tries to get the cached rocks.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@param opts? rocks.get_cached.Opts
---@return table<string, Rock[]> rocks indexed by name
function cache.try_get_rocks(opts)
    opts = opts or {}
    return try_get_unsafe(
        _cached_rocks,
        cache.populate_cached_rocks,
        opts.query_fallback and populate_cached_rocks_sync or nil
    )
end

local function populate_removable_rock_cache_sync()
    if _removable_rock_cache then
        return
    end
    _removable_rock_cache = state.query_removable_rocks()
end

---Query the state for rocks that can be removed
---and populate the cache.
---@type async fun()
cache.populate_removable_rock_cache = nio.create(populate_removable_rock_cache_sync)

---Tries to get the cached removable rocks.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@param opts? rocks.get_cached.Opts
---@return table<string, Rock[]> rocks indexed by name
function cache.try_get_removable_rocks(opts)
    opts = opts or {}
    return try_get_unsafe(
        _removable_rock_cache,
        cache.populate_removable_rock_cache,
        opts.query_fallback and populate_removable_rock_cache_sync or nil
    )
end

---Invalidate the removable rocks cache
cache.invalidate_removable_rocks = function()
    _removable_rock_cache = nil
end

local function populate_outdated_rock_cache_sync()
    if _outdated_rock_cache then
        return
    end
    _outdated_rock_cache = state.outdated_rocks()
end

---Query the state for rocks that can be removed
---and populate the cache.
---@type async fun()
cache.populate_outdated_rock_cache = nio.create(populate_outdated_rock_cache_sync)

---Populate all rocks state caches
cache.populate_all_rocks_state_caches = nio.create(function()
    cache.populate_removable_rock_cache()
    cache.populate_outdated_rock_cache()
end)
---Tries to get the cached removable rocks.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@param opts? rocks.get_cached.Opts
---@return table<string, OutdatedRock> rocks indexed by name
function cache.try_get_outdated_rocks(opts)
    opts = opts or {}
    return try_get_unsafe(
        _outdated_rock_cache,
        cache.populate_outdated_rock_cache,
        opts.query_fallback and populate_outdated_rock_cache_sync or nil
    )
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
