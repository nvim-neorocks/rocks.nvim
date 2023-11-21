---@mod rocks.constants
--
-- Copyright (C) 2023 Neorocks Org.
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
constants.ROCKS_VERSION = "0.1.0"

--- Default configuration file contents
---@type string
constants.DEFAULT_CONFIG = [[
# This is your rocks.nvim plugins declaration file.
# Here is a small yet pretty detailed example on how to use it:
#
# [plugins]
# nvim-treesitter = "semver_version-rev"  # e.g. "1.0.0-0"
#
# Here is another example if you want to tweak your plugins even more:

# [plugins.nvim-treesitter]
# version = "semver_version-rev"
# config  = "plugins/nvim-treesitter.lua"  # <- ~/.config/nvim/lua
# rock_flags = "--additional-luarocks-install-flags=here"

# Place your non-neovim rocks here
[rocks]

[plugins]
# If the plugin name contains a dot then you must add quotes to the key name!
#
"rocks.nvim" = "0.1.0-1" # rocks.nvim can also manage itself :D
]]

return constants

--- constants.lua
