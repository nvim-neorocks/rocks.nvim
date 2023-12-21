---@mod rocks.constants
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    09 Dec 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
--
---@brief [[
--
-- rocks.nvim constant variables that I do not want to write twice
--
---@brief ]]

---@type table
local constants = {}

--- Lua version to be used in luarocks
---@type string
constants.LUA_VERSION = "5.1"

--- Rocks.nvim version
---@type string
constants.ROCKS_VERSION = "2.5.0"

--- Default configuration file contents
---@type string
constants.DEFAULT_CONFIG = string.format(
    [[
# This is your rocks.nvim plugins declaration file.
# Here is a small yet pretty detailed example on how to use it:
#
# [plugins]
# nvim-treesitter = "semver_version-rev"  # e.g. "1.0.0-0"

# List of non-Neovim rocks.
# This includes things like `toml` or other lua packages.
[rocks]

# List of Neovim plugins to install alongside their versions.
# If the plugin name contains a dot then you must add quotes to the key name!
[plugins]
"rocks.nvim" = "%s" # rocks.nvim can also manage itself :D
]],
    constants.ROCKS_VERSION
)

---@type string
constants.ROCKS_NVIM = "rocks.nvim"

return constants

--- constants.lua
