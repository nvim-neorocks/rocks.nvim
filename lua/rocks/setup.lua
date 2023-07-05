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

--- Add luarocks Neovim tree paths to LUA_PATH and LUA_CPATH and download required rocks to work
---@private
local function bootstrap()
  local cfg = _G.__rocks_config
  local sep = constants.SYS_SEPARATOR

  -- First set up the paths then check if toml rock is installed or not
  local luarocks_path = {
    table.concat({ cfg.rocks_path, "share", "lua", "5.1", "?.lua" }, sep),
    table.concat({ cfg.rocks_path, "share", "lua", "5.1", "?", "init.lua" }, sep),
  }
  package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

  local luarocks_cpath = table.concat({ cfg.rocks_path, "lib64", "lua", "5.1", "?.so" }, sep)
  package.cpath = package.cpath .. ";" .. luarocks_cpath

  -- Is toml rock installed? No? Well let's install it now!
  local is_toml_installed, _ = pcall(require, "toml")
  if not is_toml_installed then
    vim.notify("Installing 'toml' dependency by using luarocks. This requires compiling C++ code so it may take a while, please wait ...")
    vim.fn.system({
      "luarocks",
      "--lua-version=" .. constants.LUA_VERSION,
      "install",
      "--tree",
      cfg.rocks_path,
      "toml",
    })

    vim.cmd.redraw()
    if vim.v.shell_error ~= 0 then
      -- As toml is the first thing that gets installed it is safe to completely nuke the Neovim luarocks tree
      -- if the installation failed so we do not keep any kind of residual junk when retrying the installation
      vim.fn.delete(cfg.rocks_path, "rf")

      vim.notify(
        "Failed to install 'toml', please relaunch Neovim to try again.",
        vim.log.levels.ERROR
      )
    else
      vim.notify(
        "Successfully installed 'toml' at '" .. cfg.rocks_path .. "'.",
        vim.log.levels.INFO
      )
    end
  end
end

--- Initialize rocks.nvim
function setup.init()
  -- Run bootstrap process, install dependencies if required
  bootstrap()

  -- We cannot require it at top-level as operations depends on bootstrapping process
  local operations = require("rocks.operations")
  -- Read configuration file and proceed with any task that has to be done with the plugins
  operations.read_config()
end

return setup

--- setup.lua ends here
