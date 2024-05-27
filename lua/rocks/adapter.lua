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
-- Updated:    19 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

local adapter = {}

local nio = require("nio")
local log = require("rocks.log")
local fs = require("rocks.fs")
local config = require("rocks.config.internal")

local rtp_link_dir = vim.fs.joinpath(config.rocks_path, "rocks_rtp")
vim.opt.runtimepath:append(rtp_link_dir)

local data_dir = vim.fn.stdpath("data")
---@cast data_dir string
local site_link_dir = vim.fs.joinpath(data_dir, "site", "pack", "luarocks", "opt")

---@type async fun(symlink_location: string, symlink_dir_name: string, dest_dir_path: string)
local create_symlink = nio.create(function(symlink_location, symlink_dir_name, dest_dir_path)
    local symlink_dir_path = vim.fs.joinpath(symlink_location, symlink_dir_name)
    local _, stat = nio.uv.fs_stat(symlink_dir_path)
    if not stat then
        log.info("Creating symlink directory: " .. symlink_dir_name)
        local err, success = nio.uv.fs_symlink(dest_dir_path, symlink_dir_path)
        if not success then
            log.error(("Error creating symlink directory: %s (%s)"):format(symlink_dir_name, err or "unknown error"))
        end
    end
end, 3)

---@param symlink_dir string
local function validate_symlink_dir(symlink_dir)
    local _, stat = nio.uv.fs_stat(symlink_dir)
    if not stat then
        local err, success = nio.uv.fs_unlink(symlink_dir)
        if not success then
            log.error(("Failed to remove symlink: %s (%s)"):format(symlink_dir, err or "unknown error"))
        end
    end
end

--- Neovim doesn't support `:checkhealth` for luarocks plugins.
--- To work around this, we create a symlink in the `rocks_path` that
--- we add to the runtimepath, so that Neovim can find health files.
local function init_checkhealth_symlink()
    local rocks_lua_dir = vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1")
    local _, stat = nio.uv.fs_stat(rocks_lua_dir)
    if stat then
        create_symlink(rtp_link_dir, "lua", rocks_lua_dir)
    end
end

--- Check if the site symlinks are valid,
--- and remove them if they aren't
function adapter.validate_site_symlinks()
    local _, handle = nio.uv.fs_scandir(site_link_dir)
    while handle do
        local name, ty = vim.uv.fs_scandir_next(handle)
        if not name then
            return
        end
        if ty == "link" then
            validate_symlink_dir(vim.fs.joinpath(site_link_dir, name))
        end
    end
end

--- @param rock Rock
local function init_site_symlink(rock)
    local rock_dir = vim.fs.joinpath(config.rocks_path, "lib", "luarocks", "rocks-5.1", rock.name)
    local _, handle = nio.uv.fs_scandir(rock_dir)
    while handle do
        local name, ty = vim.uv.fs_scandir_next(handle)
        if not name then
            return
        end
        if ty == "directory" and name:find("^" .. rock.version) ~= nil then
            local rock_version_dir = vim.fs.joinpath(rock_dir, name)
            create_symlink(site_link_dir, rock.name, rock_version_dir)
            return
        end
    end
end

--- Loop over the installed rocks and create symlinks in site/pack/luarocks/opt,
--- so that rtp paths like 'autoload' and 'color' are available before rocks.nvim
--- has initialised.
adapter.init_site_symlinks = nio.create(function()
    local state = require("rocks.state")
    for _, rock in pairs(state.installed_rocks()) do
        init_site_symlink(rock)
    end
end)

--- Initialise/validate runtimepath symlinks for tree-sitter parsers and health checks
local function init_rtp_links()
    local ok = fs.mkdir_p(rtp_link_dir)
    if not ok then
        return
    end
    init_checkhealth_symlink()
end

--- Initialise/validate site symlinks so that 'autoload' and 'colors', etc.
--- are available on the rtp (without sourcing plugins) before rocks.nvim is loaded.
local function init_site_links()
    local ok = fs.mkdir_p(site_link_dir)
    if not ok then
        return
    end
    adapter.validate_site_symlinks()
    adapter.init_site_symlinks()
end

adapter.init = nio.create(function()
    init_rtp_links()
    init_site_links()
end)

return adapter
