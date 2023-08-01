--- setup.lua --- rocks.nvim setup module
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
-- This module helps us setting up the environment for using Luarocks
-- like modifying the `package.path` and `package.cpath` Lua variables.
--
-------------------------------------------------------------------------------
--
--- Code:

local setup = {}

local constants = require("rocks.constants")
local operations = require("rocks.operations")
local config = require("rocks.config")

--- Add luarocks Neovim tree paths to LUA_PATH and LUA_CPATH and download required rocks to work
---@private
local function bootstrap()
  local cfg = _G.__rocks_config

  -- First set up the paths then check if toml rock is installed or not
  local luarocks_path = {
    vim.fs.joinpath(cfg.rocks_path, "share", "lua", "5.1", "?.lua"),
    vim.fs.joinpath(cfg.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
  }
  package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

  local luarocks_cpath = {
      vim.fs.joinpath(cfg.rocks_path, "lib", "lua", "5.1", "?.so"),
      vim.fs.joinpath(cfg.rocks_path, "lib64", "lua", "5.1", "?.so"),
  }
  package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

  -- Is toml rock installed? No? Well let's install it now!
  local is_toml_installed, _ = pcall(require, "toml")

  if not is_toml_installed then
    vim.notify("Installing 'toml' dependency by using luarocks. This requires compiling C++ code so it may take a while, please wait ...")

    operations.install("toml", "0.3.0-0")
    operations.install("nui.nvim", "0.1.0-0")
  end
end

--- Initialize rocks.nvim
function setup.init()
  -- Run bootstrap process, install dependencies if required
  bootstrap()

  -- Read configuration file and proceed with any task that has to be done with the plugins
  local config = 
end

return setup

--- setup.lua ends here
