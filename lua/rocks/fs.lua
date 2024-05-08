---@mod rocks.fs
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- Filesystem related utilities for rocks.nvim
--
-- Diagnostics are disabled because lua_ls loves to scream at libuv functions
-- like Rust borrow checker likes to scream to newbies
--
---@brief ]]

local fs = {}

local log = require("rocks.log")
local nio = require("nio")
local uv = vim.uv

--- Check if a file exists
---@param location string file path
---@return boolean
function fs.file_exists(location)
    local fd = uv.fs_open(location, "r", 438)
    if fd then
        uv.fs_close(fd)
        return true
    end
    return false
end

--- Write `contents` to a file
---@param location string file path
---@param mode string mode to open the file for
---@param contents string file contents
---@param callback? function
function fs.write_file(location, mode, contents, callback)
    local dir = vim.fn.fnamemodify(location, ":h")
    fs.mkdir_p(dir)
    -- 644 sets read and write permissions for the owner, and it sets read-only
    -- mode for the group and others
    uv.fs_open(location, mode, tonumber("644", 8), function(err, file)
        if file and not err then
            local file_pipe = uv.new_pipe(false)
            ---@cast file_pipe uv_pipe_t
            uv.pipe_open(file_pipe, file)
            uv.write(file_pipe, contents, function(write_err)
                if write_err then
                    local msg = ("Error writing %s: %s"):format(location, err)
                    log.error(msg)
                    vim.notify(msg, vim.log.levels.ERROR)
                end
                uv.fs_close(file)
                if callback then
                    callback()
                end
            end)
        else
            local msg = ("Error opening %s for writing: %s"):format(location, err)
            log.error(msg)
            vim.notify(msg, vim.log.levels.ERROR)
            if callback then
                callback()
            end
        end
    end)
end

--- Write `contents` to a file and wait in an async context
---@type async fun(location:string, mode:string, contents:string)
fs.write_file_await = nio.create(function(location, mode, contents)
    local future = nio.control.future()
    vim.schedule(function()
        fs.write_file(location, mode, contents, function()
            future.set(true)
        end)
    end)
    future.wait()
end, 3)

---Reads or creates from a file
---@param location string The location of the file
---@param default string The contents to write to the file if it doesn't exist
---@return string content The file content
function fs.read_or_create(location, default)
    local content
    if fs.file_exists(location) then
        local file = uv.fs_open(location, "r", 438)
        ---@cast file integer
        local stat = uv.fs_fstat(file)
        ---@cast stat uv.aliases.fs_stat_table
        content = uv.fs_read(file, stat.size, 0)
        ---@cast content string
        uv.fs_close(file)
    else
        content = vim.trim(default)
        fs.write_file(location, "w+", content)
    end
    ---@cast content string
    return content
end

---Create directory, including parents
---@param dir string
---@return boolean success
function fs.mkdir_p(dir)
    local mode = 493
    local mod = ""
    local path = dir
    while vim.fn.isdirectory(path) == 0 do
        mod = mod .. ":h"
        path = vim.fn.fnamemodify(dir, mod)
    end
    while mod ~= "" do
        mod = string.sub(mod, 3)
        path = vim.fn.fnamemodify(dir, mod)
        vim.uv.fs_mkdir(path, mode)
    end
    if not vim.uv.fs_stat(dir) then
        log.error("Failed to create directory: " .. dir)
        return false
    end
    return true
end

return fs

--- fs.lua ends here
