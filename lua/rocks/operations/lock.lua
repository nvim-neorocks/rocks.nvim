---@mod rocks.operations.lock
--
-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    7 Jul 2024
-- Updated:    7 Jul 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- Lockfile management.
--
---@brief ]]

local config = require("rocks.config.internal")
local fs = require("rocks.fs")
local nio = require("nio")

local lock = {}

---@param reset boolean
local function parse_rocks_lock(reset)
    local lockfile = reset and "" or fs.read_or_create(config.lockfile_path, "")
    return require("toml_edit").parse(lockfile)
end

---@param rock_name? rock_name
lock.update_lockfile = nio.create(function(rock_name)
    local luarocks_lockfiles = vim.iter(vim.api.nvim_get_runtime_file("luarocks.lock", true))
        :filter(function(path)
            return not rock_name or path:find(rock_name .. "/[^%/]+/luarocks.lock$") ~= nil
        end)
        :totable()
    local reset = rock_name == nil
    local rocks_lock = parse_rocks_lock(reset)
    for _, luarocks_lockfile in ipairs(luarocks_lockfiles) do
        local rock_key = rock_name or luarocks_lockfile:match("/([^%/]+)/[^%/]+/luarocks.lock$")
        if rock_key then
            local ok, loader = pcall(loadfile, luarocks_lockfile)
            if not ok or not loader then
                return
            end
            local success, luarocks_lock_tbl = pcall(loader)
            if not success or not luarocks_lock_tbl or not luarocks_lock_tbl.dependencies then
                return
            end
            rocks_lock[rock_key] = {}
            local has_deps = false
            for dep, version in pairs(luarocks_lock_tbl.dependencies) do
                local is_semver = pcall(vim.version.parse, version:match("([^-]+)") or version)
                if is_semver and dep ~= "lua" then
                    rocks_lock[rock_key][dep] = version
                    has_deps = true
                end
            end
            if not has_deps then
                rocks_lock[rock_key] = nil
            end
        end
    end
    fs.write_file_await(config.lockfile_path, "w", tostring(rocks_lock))
end, 1)

---@param rock_name rock_name
---@return string | nil luarocks_lock
lock.create_luarocks_lock = nio.create(function(rock_name)
    local lockfile = require("toml_edit").parse_as_tbl(fs.read_or_create(config.lockfile_path, ""))
    local dependencies = lockfile[rock_name]
    if not dependencies then
        return
    end
    local temp_dir =
        vim.fs.joinpath(vim.fn.stdpath("run") --[[@as string]], ("luarocks-lock-%X"):format(math.random(256 ^ 7)))
    fs.mkdir_p(temp_dir)
    local luarocks_lock = vim.fs.joinpath(temp_dir, "luarocks.lock")
    local content = ([[
return {
    dependencies = %s,
}
]]):format(vim.inspect(dependencies))
    fs.write_file_await(luarocks_lock, "w", content)
    return luarocks_lock
end, 1)

return lock
