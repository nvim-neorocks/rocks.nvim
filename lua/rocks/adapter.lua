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

--- Neovim doesn't support `:checkhealth` for luarocks plugins.
--- To work around this, we create a symlink in the `rocks_path` that
--- we add to the runtimepath, so that Neovim can find health files.
local function init_checkhealth_symlink()
    local health_link_dir = vim.fs.joinpath(config.rocks_path, "healthlink")
    local lua_symlink_dir = vim.fs.joinpath(health_link_dir, "lua")
    -- NOTE: nio.uv.fs_stat behaves differently than vim.uv.fs_stat
    if not vim.uv.fs_stat(lua_symlink_dir) then
        log.info("Creating health symlink directory.")
        if vim.fn.mkdir(health_link_dir, "p") ~= 1 then
            log.error("Failed to create health symlink directory.")
        end
        local rocks_lua_dir = vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1")
        nio.uv.fs_symlink(rocks_lua_dir, lua_symlink_dir)
    end
    vim.schedule(function()
        vim.opt.runtimepath:append(health_link_dir)
    end)
end

function adapter.init()
    nio.run(function()
        init_checkhealth_symlink()
    end)
end

return adapter
