--- setup.lua --- rocks.nvim setup module
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
--
-------------------------------------------------------------------------------
--
--- Commentary:
--
-- This module helps us setting up the environment for using Luarocks
-- like modifying the `package.path` and `package.cpath` Lua variables.
--
-------------------------------------------------------------------------------
--
--- Code:

local setup = {}

local constants = require("rocks.constants")
local config = require("rocks.config")

local function bootstrap_install(name, version)
    vim.system({
        "luarocks",
        "--lua-version=" .. constants.LUA_VERSION,
        "--tree=" .. config.rocks_path,
        "install",
        name,
        version,
    }):wait()
end

--- Initialize rocks.nvim
--- Add luarocks Neovim tree paths to LUA_PATH and LUA_CPATH and download required rocks to work
function setup.init()
    -- First set up the paths then check if toml rock is installed or not
    local luarocks_path = {
        vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?.lua"),
        vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
    }
    package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

    local luarocks_cpath = {
        vim.fs.joinpath(config.rocks_path, "lib", "lua", "5.1", "?.so"),
        vim.fs.joinpath(config.rocks_path, "lib64", "lua", "5.1", "?.so"),
    }
    package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

    -- Is toml rock installed? No? Well let's install it now!
    local is_toml_installed, _ = pcall(require, "toml")

    if not is_toml_installed then
        vim.ui.select({ "Ok" }, {
            prompt = "Installing 'toml' dependency via luarocks. This requires compiling C++ code so it may take a while, please wait...",
        }, function()
            vim.schedule(function()
                bootstrap_install("toml", "0.3.0-0")
                bootstrap_install("nui.nvim", "0.2.0-1")
            end)
        end)
    end
end

return setup

--- setup.lua ends here
