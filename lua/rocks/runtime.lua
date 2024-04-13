---@mod rocks rocks.runtime
---
---@brief [[
---
---Functions for adding rocks to the runtimepath and sourcing them
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    25 Dec 2023
-- Updated:    11 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

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
            local ok, err = pcall(vim.cmd.source, script)
            if not ok and type(err) == "string" then
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

---@class PackaddOpts: rocks.PackaddOpts
---@field error_on_not_found? boolean Notify with an error message if no plugin could be found. Ignored if `packadd_fallback` is set to `true`.

---@param rock_name rock_name
---@param opts? rocks.PackaddOpts
function runtime.packadd(rock_name, opts)
    ---@cast rock_name rock_name
    opts = vim.tbl_deep_extend("force", {
        bang = false,
        packadd_fallback = true,
        error_on_not_found = false,
    }, opts or {})
    ---@cast opts PackaddOpts
    local rtp_glob = mk_rtp_glob(rock_name)
    rtp_append(rtp_glob)
    if opts.bang then
        return
    end
    local paths = vim.fn.glob(rtp_glob, nil, true)
    if #paths == 0 then
        local ok, packadd_err = false, nil
        if opts.packadd_fallback then
            ok, packadd_err = pcall(vim.cmd.packadd, { rock_name, bang = opts.bang })
        end
        if not ok and opts.error_on_not_found then
            vim.notify(("No path found for %s"):format(rock_name), vim.log.levels.ERROR)
            if packadd_err then
                vim.notify(packadd_err, vim.log.levels.ERROR)
            end
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

---Source the `plugin` and `ftdetect` directories
---@param dir string
function runtime.source_rtp_dir(dir)
    source_plugin(dir)
    source_ftdetect(dir)
end

---@param rock_spec RockSpec
---@return boolean?
local function is_start_plugin(rock_spec)
    return not rock_spec.opt and rock_spec.version and rock_spec.name ~= constants.ROCKS_NVIM
end

---Add all plugins with `opt ~= true` to the rtp
function runtime.rtp_append_start_plugins(user_rocks)
    log.trace("Adding start plugins to the runtimepath")
    -- TODO: (?) Do this recursively for each rocks dependencies?
    -- I'm saying YAGNI for now, because it means querying luarocks,
    -- which isn't ideal for performance.
    -- `autoload` doesn't seem very common among lua plugins.
    for _, rock_spec in pairs(user_rocks) do
        if is_start_plugin(rock_spec) then
            rtp_append(rock_spec.name)
        end
    end
end

---Source all plugins with `opt ~= true`
---NOTE: We don't want this to be async,
---to ensure Neovim sources `after/plugin` scripts
---after we source start plugins.
---@param user_rocks RockSpec[]
function runtime.source_start_plugins(user_rocks)
    log.trace("Sourcing start plugins")
    for _, rock_spec in pairs(user_rocks) do
        if is_start_plugin(rock_spec) then
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
