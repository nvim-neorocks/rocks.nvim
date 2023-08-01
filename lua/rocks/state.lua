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

--- 
---@param callback fun(installed: string[])
function state.installed_rocks(callback)
    vim.system({"luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "list", "--porcelain"}, function(obj)

    end)
end

return state
