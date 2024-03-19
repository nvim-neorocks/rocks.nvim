---@mod rocks.adapter luarocks to neovim adapter
---
---@brief [[
---
---Some Neovim features don't natively work with luarocks.
---This module provides an adapter between luarocks and neovim
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    13 Mar 2024
-- Updated:    13 Mar 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

local adapter = {}

local nio = require("nio")
local log = require("rocks.log")
local config = require("rocks.config.internal")

local rtp_link_dir = vim.fs.joinpath(config.rocks_path, "rocks_rtp")
local rocks_parser_dir = vim.fs.joinpath(config.rocks_path, "lib", "lua", "5.1", "parser")

--- Initialise the rocks_rtp directory
---@return boolean success
local function init_rocks_rtp_dir()
    if not vim.uv.fs_stat(rtp_link_dir) and vim.fn.mkdir(rtp_link_dir, "p") ~= 1 then
        log.error("Failed to create rocks_rtp symlink directory.")
        return false
    end
    return true
end

---@type async fun(symlink_dir_name: string, dest_dir_path: string)
local add_rtp_symlink = nio.create(function(symlink_dir_name, dest_dir_path)
    local symlink_dir_path = vim.fs.joinpath(rtp_link_dir, symlink_dir_name)
    -- NOTE: nio.uv.fs_stat behaves differently than vim.uv.fs_stat
    if not vim.uv.fs_stat(symlink_dir_path) then
        log.info("Creating symlink directory: " .. symlink_dir_name)
        nio.uv.fs_symlink(dest_dir_path, symlink_dir_path)
    end
end, 2)

--- Neovim doesn't support `:checkhealth` for luarocks plugins.
--- To work around this, we create a symlink in the `rocks_path` that
--- we add to the runtimepath, so that Neovim can find health files.
local function init_checkhealth_symlink()
    local rocks_lua_dir = vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1")
    if vim.uv.fs_stat(rocks_lua_dir) then
        add_rtp_symlink("lua", rocks_lua_dir)
    end
end

--- If any tree-sitter parsers are installed,
-- initialise a symlink so that Neovim can find them.
function adapter.init_tree_sitter_parser_symlink()
    if vim.uv.fs_stat(rocks_parser_dir) then
        add_rtp_symlink("parser", rocks_parser_dir)
    end
end

--- Check if the tree-sitter parser symlink is valid,
--- and remove it if it isn't
function adapter.validate_tree_sitter_parser_symlink()
    local symlink_dir_path = vim.fs.joinpath(rtp_link_dir, "parser")
    if not vim.uv.fs_stat(rocks_parser_dir) and not vim.uv.fs_unlink(symlink_dir_path) then
        log.error("Failed to remove 'parser' symlink: " .. symlink_dir_path)
    end
end

function adapter.init()
    vim.opt.runtimepath:append(rtp_link_dir)
    nio.run(function()
        local ok = init_rocks_rtp_dir()
        if not ok then
            return
        end
        init_checkhealth_symlink()
        adapter.validate_tree_sitter_parser_symlink()
        adapter.init_tree_sitter_parser_symlink()
    end)
end

return adapter
