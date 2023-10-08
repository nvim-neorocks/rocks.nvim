---@mod rocks.setup
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
---@brief [[
--
-- This module helps us setting up the environment for using Luarocks
-- like modifying the `package.path` and `package.cpath` Lua variables.
--
---@brief ]]

local setup = {}

local config = require("rocks.config")
local luarocks = require("rocks.luarocks")

local function bootstrap_install(name, version)
    luarocks
        .cli({
            "install",
            name,
            version,
        })
        :wait()
end

--- Initialize rocks.nvim
--- Add luarocks Neovim tree paths to LUA_PATH and LUA_CPATH and download required rocks to work
function setup.init()
    -- Set up the paths then check if toml rock is installed or not
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

    vim.opt.runtimepath:append(vim.fs.joinpath(config.rocks_path, "lib", "luarocks", "rocks-5.1", "*", "*"))

    -- Is the toml rock installed? No? Well let's install it now!
    local is_toml_installed, _ = pcall(require, "toml")

    if not is_toml_installed then
        vim.ui.select({ "Ok" }, {
            prompt = "Installing the 'toml' and `toml-edit` dependencies via luarocks. This requires compiling C++ and Rust code so it may take a while, please wait...",
        }, function(choice)
            if choice == nil then
                vim.cmd.qa()
            end

            vim.schedule(function()
                bootstrap_install("toml", "0.3.0-0")
                bootstrap_install("toml-edit", "0.1.4-1")
                bootstrap_install("nui.nvim", "0.2.0-1")
                vim.notify("Installation complete! Please restart your editor.")
            end)
        end)
    end
end

return setup

--- setup.lua ends here
