---@mod lux.cache lux.nvim package cache
---
---@brief [[
---
---Cached package state.
---
---@brief ]]

local cache = {}

local config = require("lux-nvim.config")
local nio = require("nio")

---@type table<package, Package[]> | nil
local _cached_packages = nil

---@type table<package_name, Package[]> | nil
local _cached_dev_binaries = nil

---Used for completions only
---@type string[] | nil
local _removable_package_cache = nil

---@type table<package_name, OutdatedPackage> | nil
local _outdated_package_cache = nil

---Tries to get the cached value
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---WARNING: `cache_ref` MUST be populated by `populate`
---
---@generic T
---@param cache_ref T
---@param populate async fun():T Stateul
---@return table<string, T> result indexed by name
local function try_get_unsafe(cache_ref, populate)
    if not cache_ref then
        nio.run(populate)
        local result = vim.empty_dict()
        return result
    end
    return cache_ref
end

---Query luarocks packages and populate the cache.
---@type async fun()
cache.populate_cached_packages = nio.create(function()
    if _cached_packages then
        return
    end
    luarocks.search_all(function(packages)
        if not vim.tbl_isempty(packages) then
            _cached_packages = packages
            vim.schedule(function()
                vim.api.nvim_exec_autocmds("User", {
                    pattern = "LuxCachePopulated",
                    modeline = false,
                    data = _cached_packages,
                })
            end)
        end
    end, {
        dev = true,
    })
end)

---Tries to get the cached packages.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@return table<string, Package[]> packages indexed by name
function cache.try_get_packages()
    return try_get_unsafe(_cached_packages, cache.populate_cached_packages)
end

---Query the state for packages that can be removed
---and populate the cache.
---@type async fun()
cache.populate_removable_package_cache = nio.create(function()
    if _removable_package_cache then
        return
    end
    _removable_package_cache = state.query_removable_packages()
    vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", {
            pattern = "LuxRemovablePackageCachePopulated",
            modeline = false,
            data = _removable_package_cache,
        })
    end)
end)

---Tries to get the cached removable packages.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@return table<string, Package[]> packages indexed by name
function cache.try_get_removable_packages()
    return try_get_unsafe(_removable_package_cache, cache.populate_removable_package_cache)
end

---Invalidate the removable package cache
cache.invalidate_removable_packages = function()
    _removable_package_cache = nil
end

---Query the state for packages that can be removed
---and populate the cache.
---@type async fun()
cache.populate_outdated_package_cache = nio.create(function()
    if _outdated_package_cache then
        return
    end
    _outdated_package_cache = state.outdated_packages()
    vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", {
            pattern = "LuxOutdatedPackageCachePopulated",
            modeline = false,
            data = _outdated_package_cache,
        })
    end)
end)

---Populate all package state caches
cache.populate_all_package_state_caches = nio.create(function()
    cache.populate_removable_package_cache()
    cache.populate_outdated_package_cache()
end)
---Tries to get the cached removable packages.
---Returns an empty list if the cache is not ready,
---and triggers an async task to populate the cache.
---@return table<string, OutdatedPackage> packages indexed by name
function cache.try_get_outdated_packages()
    return try_get_unsafe(_outdated_package_cache, cache.populate_outdated_package_cache)
end

---Search the cache for rocks-binaries-dev packages.
---Repopulates the cache and runs a second search if not found
---@type async fun(package_name: string, version: string?)
cache.search_binary_dev_packages = nio.create(function(package_name, version)
    ---@cast package_name package_name
    ---@cast version string
    local function search_cache()
        local packages
        if _cached_dev_binaries then
            packages = _cached_dev_binaries[package_name]
        end
        return packages
            and vim.iter(packages):any(function(package)
                ---@cast package Package
                if version == "dev" then
                    version = "scm"
                end
                return not version or package.version == version
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
        servers = config.get_dev_servers(),
    })
    future.wait()
    return search_cache()
end, 2)

return cache
