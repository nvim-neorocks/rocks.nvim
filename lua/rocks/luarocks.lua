---@mod rocks.luarocks
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    19 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>
--
---@brief [[
--
-- Functions for interacting with the luarocks CLI
--
---@brief ]]

local luarocks = {}

local constants = require("rocks.constants")
local config = require("rocks.config.internal")
local nio = require("nio")

---@param args string[] luarocks CLI arguments
---@param on_exit (function|nil) Called asynchronously when the luarocks command exits.
---   asynchronously. Receives SystemCompleted object, see return of SystemObj:wait().
---@param opts? SystemOpts
---@return vim.SystemObj
---@see vim.system
luarocks.cli = function(args, on_exit, opts)
    local luarocks_cmd = vim.list_extend({
        config.luarocks_binary,
        "--lua-version=" .. constants.LUA_VERSION,
        "--tree=" .. config.rocks_path,
        "--server='https://nvim-neorocks.github.io/rocks-binaries/'",
    }, args)
    return vim.system(luarocks_cmd, opts, on_exit and vim.schedule_wrap(on_exit))
end

---Search luarocks.org for all packages.
---@type async fun(callback: fun(rocks_table: { [string]: Rock } ))
luarocks.search_all = nio.create(function(callback)
    local rocks_table = vim.empty_dict()
    ---@cast rocks_table { [string]: Rock }
    local future = nio.control.future()
    luarocks.cli({ "search", "--porcelain", "--all" }, function(obj)
        ---@cast obj vim.SystemCompleted
        future.set(obj)
    end, { text = true })
    ---@type vim.SystemCompleted
    local obj = future.wait()
    local result = obj.stdout
    if obj.code ~= 0 or not result then
        callback(vim.empty_dict())
        return
    end
    for name, version in result:gmatch("(%S+)%s+(%S+)%srockspec%s+[^\n]+") do
        if name ~= "lua" then
            local rock_list = rocks_table[name] or vim.empty_dict()
            ---@cast rock_list Rock[]
            table.insert(rock_list, { name = name, version = version })
            rocks_table[name] = rock_list
        end
    end
    callback(rocks_table)
end)

return luarocks

-- end of luarocks.lua
