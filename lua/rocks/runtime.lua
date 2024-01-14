---@mod rocks rocks.runtime
---
---@brief [[
---
---Functions for adding rocks to the runtimepath and sourcing them
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    25 Dec 2023
-- Updated:    25 Dec 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>

local runtime = {}

local config = require("rocks.config.internal")
local constants = require("rocks.constants")
local log = require("rocks.log")
local fzy = require("rocks.fzy")

---@alias rock_pattern "*" | rock_name

---paths should only be appended to the rtp once
---@type table<string, boolean|nil>
local _appended_rtp = {}

---`ftdetect` scripts should only be sourced once.
---@type table<string, boolean|nil>
local _sourced_ftdetect = {}

---@enum RtpSourceDir Directories to be sourced on packadd
local RtpSourceDir = {
    plugin = "plugin",
    ftdetect = "ftdetect",
}

---Recursively iterate over a directory's children
---@param dir string
---@return fun(_:any, path:string):(path: string, name: string, type: string)
---@async
local function iter_children(dir)
    return coroutine.wrap(function()
        local handle = vim.uv.fs_scandir(dir)
        while handle do
            local name, ty = vim.uv.fs_scandir_next(handle)
            local path = vim.fs.joinpath(dir, name)
            ty = ty or vim.uv.fs_stat(path).type
            if not name then
                return
            elseif ty == "directory" then
                for child_path, child, child_type in iter_children(path) do
                    coroutine.yield(child_path, child, child_type)
                end
            end
            coroutine.yield(path, name, ty)
        end
    end)
end

---@param rtp_source_dir RtpSourceDir
---@param dir string
local function source(rtp_source_dir, dir)
    local rtp_dir = vim.fs.joinpath(dir, rtp_source_dir)
    for script, name, ty in iter_children(rtp_dir) do
        local ext = name:sub(-3)
        if vim.tbl_contains({ "file", "link" }, ty) and vim.tbl_contains({ "lua", "vim" }, ext) then
            local co = coroutine.create(vim.cmd.source)
            local ok = coroutine.resume(co, script)
            if not ok then
                local err = debug.traceback(co, "rocks.nvim: Error to sourcing " .. name)
                log.error(err)
                vim.notify(err, vim.log.levels.ERROR)
                break
            end
        end
    end
end

---@param dir string
local function source_plugin(dir)
    source(RtpSourceDir.plugin, dir)
end

---@param dir string
local function source_ftdetect(dir)
    if not _sourced_ftdetect[dir] then
        source(RtpSourceDir.ftdetect, dir)
        _sourced_ftdetect[dir] = true
    end
end

---@param rock_pattern rock_pattern
---@return string rtp_path The runtime path, with a glob star for the version
local function mk_rtp_glob(rock_pattern)
    return vim.fs.joinpath(config.rocks_path, "lib", "luarocks", "rocks-5.1", rock_pattern:lower(), "*")
end

---Append a glob to the runtimepath, if not already appended.
---@param rtp_glob string
local function rtp_append(rtp_glob)
    if _appended_rtp[rtp_glob] then
        return
    end
    vim.opt.runtimepath:append(rtp_glob)
    _appended_rtp[rtp_glob] = true
end

---@class (exact) PackaddOpts
---@field bang? boolean
---@field error_on_not_found? boolean

---@param rock_name rock_name
---@param opts? PackaddOpts
function runtime.packadd(rock_name, opts)
    ---@cast rock_name rock_name
    ---@cast opts table
    opts = vim.tbl_deep_extend("force", {
        bang = false,
        error_on_not_found = true,
    }, opts or {})
    local rtp_glob = mk_rtp_glob(rock_name)
    rtp_append(rtp_glob)
    if opts.bang then
        return
    end
    local paths = vim.fn.glob(rtp_glob, nil, true)
    if #paths == 0 then
        if opts.error_on_not_found then
            vim.notify(("No path found for %s"):format(rock_name), vim.log.levels.ERROR)
        end
        return
    end
    local path = paths[1]
    if #paths > 1 then
        local dir = vim.fn.fnamemodify(path, ":t")
        vim.notify(
            ("More than one version found for rock %s. Sourcing %s."):format(rock_name, dir),
            vim.log.levels.WARN
        )
    end
    source_plugin(path)
    source_ftdetect(path)
end

---Source all plugins with `opt ~= true`
---NOTE: We don't want this to be async,
---to ensure Neovim sources `after/plugin` scripts
---after we source start plugins.
function runtime.source_start_plugins()
    local user_rocks = config.get_user_rocks()
    for _, rock_spec in pairs(user_rocks) do
        if not rock_spec.opt and rock_spec.version and rock_spec.name ~= constants.ROCKS_NVIM then
            -- Append to rtp first in case a plugin needs another plugin's `autoload`
            -- TODO: (?) Do this recursively for each rocks dependencies?
            -- I'm saying YAGNI for now, because it means querying luarocks,
            -- which isn't ideal for performance.
            -- `autoload` doesn't seem very common among lua plugins.
            rtp_append(rock_spec.name)
            runtime.packadd(rock_spec.name, { error_on_not_found = false })
        end
    end
end

---Get completions from rocks.toml for the `:Rocks packadd` command
---@param query string
function runtime.complete_packadd(query)
    local opt_rocks = vim.iter(vim.tbl_values(config.get_user_rocks()))
        :filter(function(rock_spec)
            return rock_spec.opt and rock_spec.version
        end)
        :map(function(rock_spec)
            return rock_spec.name
        end)
        :totable()
    return fzy.fuzzy_filter(query, opt_rocks)
end

return runtime
