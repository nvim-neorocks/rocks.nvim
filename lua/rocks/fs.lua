--- fs.lua --- rocks.nvim fs module
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    05 Jul 2023
-- Homepage:   https://github.com/NTBBloodbath/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
--
-------------------------------------------------------------------------------
--
--- Commentary:
--
-- Filesystem related utilities for rocks.nvim
--
-- Diagnostics are disabled because lua_ls loves to scream at libuv functions
-- like Rust borrow checker likes to scream to newbies
--
-------------------------------------------------------------------------------
--
--- Code:

local fs = {}

--- Check if a file exists
---@param location string file path
---@return boolean
function fs.file_exists(location)
    local fd = vim.loop.fs_open(location, "r", 438)
    if fd then
        vim.loop.fs_close(fd)
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
    vim.loop.fs_open(location, mode, tonumber("644", 8), function(err, file)
        if not err then
            local file_pipe = vim.loop.new_pipe(false)
            ---@diagnostic disable-next-line
            vim.loop.pipe_open(file_pipe, file)
            ---@diagnostic disable-next-line
            vim.loop.write(file_pipe, contents)
            ---@diagnostic disable-next-line
            vim.loop.fs_close(file)
        end
    end)
end

---Reads or creates from a file
---@param location string The location of the file
---@param default string The contents to write to the file if it doesn't exist
function fs.read_or_create(location, default)
    local content
    if fs.file_exists(location) then
        local file = vim.loop.fs_open(location, "r", 438)
        ---@diagnostic disable-next-line
        local stat = vim.loop.fs_fstat(file)
        ---@diagnostic disable-next-line
        content = vim.loop.fs_read(file, stat.size, 0)
        ---@diagnostic disable-next-line
        vim.loop.fs_close(file)
    else
        content = vim.trim(default)
        fs.write_file(location, "w+", content)
    end

    return content
end

return fs

--- fs.lua ends here
