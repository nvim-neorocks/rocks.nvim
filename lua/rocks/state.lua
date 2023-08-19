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

---@alias Rock { name: string, version: string, target_version?: string }

--- 
---@param callback fun(installed: {[string]: Rock})
function state.installed_rocks(callback)
    local _callback = function(obj)
        ---@type {[string]: Rock}
        local rocks = {}

        for name, version in obj.stdout:gmatch("([^%s]+)%s+(%d+%.%d+%.%d+%-%d+)%s+installed%s+[^%s]+") do
            rocks[name] = { name = name, version = version }
        end

        if callback then
            callback(rocks)
        else
            return rocks
        end
    end

    if callback then
        vim.system({"luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "list", "--porcelain"}, _callback)
    else
        local rocklist = vim.system({"luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "list", "--porcelain"}):wait()
        return _callback(rocklist)
    end
end

---@param callback fun(installed: {[string]: Rock})
function state.outdated_rocks(callback)
    local _callback = function(obj)
        ---@type {[string]: Rock}
        local rocks = {}

        vim.print(obj.stdout)
        for name, version, target_version in obj.stdout:gmatch("([^%s]+)%s+(%d+%.%d+%.%d+%-%d+)%s+(%d+%.%d+%.%d+%-%d+)%s+[^%s]+") do
            rocks[name] = { name = name, version = version, target_version = target_version }
        end

        if callback then
            callback(rocks)
        else
            return rocks
        end
    end

    if callback then
        vim.system({"luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "list", "--porcelain", "--outdated"}, _callback)
    else
        local rocklist = vim.system({"luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "list", "--porcelain", "--outdated"}):wait()
        return _callback(rocklist)
    end
end

return state
