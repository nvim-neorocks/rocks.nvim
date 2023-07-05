--- config.lua --- rocks.nvim config module
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
-- rocks.nvim configuration options
--
-------------------------------------------------------------------------------
--
--- Code:

local separator = require("rocks.constants").SYS_SEPARATOR

--- rocks.nvim configuration
---@type table
local config = {
  --- Local path in your filesystem to install rocks
  ---@type string
  rocks_path = vim.fn.stdpath("data") .. separator .. "rocks",
  --- Rocks declaration file path
  ---@type string
  config_path = vim.fn.stdpath("config") .. separator .. "rocks.toml",
}

return config

--- config.lua ends here
