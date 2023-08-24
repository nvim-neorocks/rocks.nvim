--- state.lua --- rocks.nvim config module
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    19 Jul 2023
-- Updated:    19 Jul 2023
-- Homepage:   https://github.com/NTBBloodbath/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>
--
-------------------------------------------------------------------------------------------
--
--- Commentary:
--
-- rocks.nvim configuration options
--
-------------------------------------------------------------------------------------------
--
--- Code:

local state = {}

local constants = require("rocks.constants")
local config = require("rocks.config")
local nio = require("nio")

---@type fun(): {[string]: Rock}
---@async
state.installed_rocks = nio.create(function()
    ---@type {[string]: Rock}
    local rocks = {}

    local future = nio.control.future()

    vim.system(
        { "luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "list", "--porcelain" },
        { text = true },
        function(obj)
            -- TODO: Error handling
            future.set(obj.stdout)
        end
    )

    local installed_rock_list = future.wait()

    for name, version in installed_rock_list:gmatch("([^%s]+)%s+(%d+%.%d+%.%d+%-%d+)%s+installed%s+[^%s]+") do
        rocks[name] = { name = name, version = version }
    end

    return rocks
end)

state.outdated_rocks = nio.create(function()
    ---@type {[string]: Rock}
    local rocks = {}

    local future = nio.control.future()

    vim.system({
        "luarocks",
        "--lua-version=" .. constants.LUA_VERSION,
        "--tree=" .. config.rocks_path,
        "list",
        "--porcelain",
        "--outdated",
    }, { text = true }, function(obj)
        -- TODO: Error handling
        future.set(obj.stdout)
    end)

    local installed_rock_list = future.wait()

    for name, version, target_version in
        installed_rock_list:gmatch("([^%s]+)%s+(%d+%.%d+%.%d+%-%d+)%s+(%d+%.%d+%.%d+%-%d+)%s+[^%s]+")
    do
        rocks[name] = { name = name, version = version, target_version = target_version }
    end

    return rocks
end)

return state
