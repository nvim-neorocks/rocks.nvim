---@mod rocks.fs
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
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

---@diagnostic disable-next-line: deprecated
local uv = vim.uv or vim.loop

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
function fs.write_file(location, mode, contents)
    -- 644 sets read and write permissions for the owner, and it sets read-only
    -- mode for the group and others
    uv.fs_open(location, mode, tonumber("644", 8), function(err, file)
        if file and not err then
            local file_pipe = uv.new_pipe(false)
            ---@cast file_pipe uv_pipe_t
            uv.pipe_open(file_pipe, file)
            uv.write(file_pipe, contents)
            uv.fs_close(file)
        end
    end)
end

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

return fs

--- fs.lua ends here
