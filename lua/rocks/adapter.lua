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

-- NOTE: On Windows, we must create junctions, because NTFS symlinks require admin privileges.

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

---@param symlink_location string
---@param symlink_dir_name string
---@param dest_dir_path string
---@return boolean
local function create_symlink_sync(symlink_location, symlink_dir_name, dest_dir_path)
    local symlink_dir_path = vim.fs.joinpath(symlink_location, symlink_dir_name)
    local stat = vim.uv.fs_stat(symlink_dir_path)
    if stat then
        log.debug(("Symlink directory %s exists already."):format(symlink_dir_name))
        return true
    else
        log.debug(("Creating symlink directory: %s"):format(symlink_dir_name))
        local success, err = vim.uv.fs_symlink(dest_dir_path, symlink_dir_path, { junction = true })
        if not success then
            log.error(("Error creating symlink directory: %s (%s)"):format(symlink_dir_name, err or "unknown error"))
        end
        return success or false
    end
end

----@type async fun(symlink_location: string, symlink_dir_name: string, dest_dir_path: string)
local create_symlink_async = nio.create(function(symlink_location, symlink_dir_name, dest_dir_path)
    local symlink_dir_path = vim.fs.joinpath(symlink_location, symlink_dir_name)
    local _, stat = nio.uv.fs_stat(symlink_dir_path)
    if stat then
        log.debug(("Symlink directory %s exists already."):format(symlink_dir_name))
    else
        log.debug(("Creating symlink directory: %s"):format(symlink_dir_name))
        ---@diagnostic disable-next-line: param-type-mismatch
        local err, success = nio.uv.fs_symlink(dest_dir_path, symlink_dir_path, { junction = true })
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
        create_symlink_sync(rtp_link_dir, "lua", rocks_lua_dir)
    end
end

--- Check if the site symlinks are valid,
--- and remove them if they aren't
local function validate_site_symlinks_async()
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

---@param rock RockSpec | Rock
---@return string
local function get_rock_dir(rock)
    return vim.fs.joinpath(config.rocks_path, "lib", "luarocks", "rocks-5.1", rock.name)
end

---@param rock Rock
local function init_site_symlink_async(rock)
    local rock_dir = get_rock_dir(rock)
    local _, handle = nio.uv.fs_scandir(rock_dir)
    while handle do
        local dir_name, ty = vim.uv.fs_scandir_next(handle)
        if not dir_name then
            return
        end
        if ty == "directory" and dir_name:find("^" .. rock.version) ~= nil then
            local rock_version_dir = vim.fs.joinpath(rock_dir, dir_name)
            return create_symlink_async(site_link_dir, rock.name, rock_version_dir)
        end
    end
end

---Check if a site symlink exists for a rock
---@param rock RockSpec | Rock
---@return boolean exists
function adapter.has_site_symlink(rock)
    local symlink_dir_path = vim.fs.joinpath(site_link_dir, rock.name)
    return vim.uv.fs_stat(symlink_dir_path) ~= nil
end

---Synchronously initialise a site symlink
---@param rock RockSpec | Rock
---@return boolean created
function adapter.init_site_symlink_sync(rock)
    if not rock.version then
        log.info("Cannot init site symlink without rock version")
        return false
    end
    local rock_dir = get_rock_dir(rock)
    local handle = vim.uv.fs_scandir(rock_dir)
    while handle do
        local dir_name, ty = vim.uv.fs_scandir_next(handle)
        if not dir_name then
            return false
        end
        if ty == "directory" and dir_name:find("^" .. rock.version) ~= nil then
            local rock_version_dir = vim.fs.joinpath(rock_dir, dir_name)
            return create_symlink_sync(site_link_dir, rock.name, rock_version_dir)
        end
    end
    return false
end

--- Loop over the installed rocks and create symlinks in site/pack/luarocks/opt,
--- so that colorschemes are available before rocks.nvim
--- has initialised.
local function init_site_symlinks_async()
    local state = require("rocks.state")
    vim
        .iter(state.installed_rocks())
        ---@param rock Rock
        :filter(function(_, rock)
            return not vim.startswith(rock.name, "tree-sitter-")
        end)
        ---@param rock Rock
        :each(function(_, rock)
            init_site_symlink_async(rock)
            -- Make autoload scripts available
            -- Since we're invoking this in the :h load-plugins phase of the startup sequence,
            -- this packadd! call won't result in any scripts being sourced.
            nio.scheduler()
            local ok, err = pcall(vim.cmd.packadd, { rock.name, bang = true })
            if not ok then
                log.error(err)
            end
        end)
end

--- Initialise/validate runtimepath symlinks for tree-sitter parsers and health checks
local function ensure_rtp_links()
    local ok = fs.mkdir_p(rtp_link_dir)
    if not ok then
        return
    end
    init_checkhealth_symlink()
end

local function ensure_site_links()
    local ok = fs.mkdir_p(site_link_dir)
    if not ok then
        return
    end
    adapter.synchronise_site_symlinks()
end

--- Reinitialise/validate site symlinks so that 'autoload' and 'colors', etc.
--- are available on the rtp (without sourcing plugins) before rocks.nvim is loaded.
---@type async fun()
adapter.synchronise_site_symlinks = nio.create(function()
    validate_site_symlinks_async()
    init_site_symlinks_async()
end)

---@type async fun()
adapter.init = nio.create(function()
    ensure_rtp_links()
    ensure_site_links()
end)

return adapter
