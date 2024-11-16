---@mod rocks.constants
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    09 Dec 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
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
constants.ROCKS_VERSION = "2.42.1"

--- Default configuration file contents
---@type string
constants.DEFAULT_CONFIG = string.format(
    [[
# This is your rocks.nvim plugins declaration file.
# Here is a small yet pretty detailed example on how to use it:
#
# [plugins]
# nvim-treesitter = "semver_version"  # e.g. "1.0.0"

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

---@alias server_url string
---@alias only_server_url string

--- WARNING: The servers are prioritised by luarocks in the reverse order
--- in which they are passed
---@type server_url[]
constants.DEFAULT_ROCKS_SERVERS = {
    "https://luarocks.org/manifests/neorocks/",
    "https://nvim-neorocks.github.io/rocks-binaries/",
}

---@type only_server_url
constants.ROCKS_BINARIES_DEV = "https://nvim-neorocks.github.io/rocks-binaries-dev/"

---@type server_url[]
constants.DEFAULT_DEV_SERVERS = {
    constants.ROCKS_BINARIES_DEV,
}

constants.STUB_ROCKSPEC_TEMPLATE = [==[
package = "%s"
version = "%s-1"

source = {
    url = 'https://github.com/nvim-neorocks/luarocks-stub/archive/548853648d7cff7e0d959ff95209e8aa97a793bc.zip',
    dir = 'luarocks-stub-548853648d7cff7e0d959ff95209e8aa97a793bc',
}

dependencies = %s

build = {
    type = "builtin",
    modules = {}
}
]==]

return constants

--- constants.lua
