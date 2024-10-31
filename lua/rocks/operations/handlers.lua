---@mod rocks.operations.helpers
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    07 Mar 2024
-- Updated:    07 Mar 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- This module takes care of getting and delegating to external handlers for
-- operations related to managing rocks. Installing, uninstalling, updating, etc.
--
---@brief ]]

local handlers = {}

local helpers = require("rocks.operations.helpers")

---@type RockHandler[]
local _handlers = {}

---@param handler RockHandler
function handlers.register_handler(handler)
    table.insert(_handlers, handler)
end

---@overload fun(rocks_toml_ref: MultiMutRocksTomlWrapper, arg_list: string[]): rock_handler_callback | nil
---@param rocks_toml_ref MutRocksTomlRef
---@param arg_list string[]
---@return rock_handler_callback | nil
function handlers.get_install_handler_callback(rocks_toml_ref, arg_list)
    return vim.iter(_handlers)
        :filter(function(handler)
            ---@cast handler RockHandler
            return type(handler.get_install_callback) == "function"
        end)
        :map(function(handler)
            ---@cast handler RockHandler
            local get_callback = handler.get_install_callback
            return type(get_callback) == "function" and get_callback(rocks_toml_ref, arg_list)
        end)
        :find(function(callback)
            return callback ~= nil
        end)
end

---@param spec RockSpec
---@return rock_handler_callback | nil
function handlers.get_sync_handler_callback(spec)
    return vim.iter(_handlers)
        :filter(function(handler)
            ---@cast handler RockHandler
            return type(handler.get_sync_callback) == "function"
        end)
        :map(function(handler)
            ---@cast handler RockHandler
            return handler.get_sync_callback(spec)
        end)
        :find(function(callback)
            return callback ~= nil
        end)
end

---@overload fun(rocks_toml_ref: MultiMutRocksTomlWrapper): rock_handler_callback[]
---@param rocks_toml_ref MutRocksTomlRef
---@return rock_handler_callback[]
function handlers.get_update_handler_callbacks(rocks_toml_ref)
    return vim.iter(_handlers)
        :filter(function(handler)
            ---@cast handler RockHandler
            return type(handler.get_update_callbacks) == "function"
        end)
        :map(function(handler)
            ---@cast handler RockHandler
            return handler.get_update_callbacks(rocks_toml_ref) or {}
        end)
        :flatten()
        :totable()
end

---Tell external handlers to prune their rocks
---@param user_rocks table<rock_name, RockSpec>
---@param on_progress fun(message: string)
---@param on_error fun(message: string)
handlers.prune_user_rocks = function(user_rocks, on_progress, on_error)
    for _, handler in pairs(_handlers) do
        local callback = type(handler.get_prune_callback) == "function" and handler.get_prune_callback(user_rocks)
        if callback then
            callback(on_progress, on_error, helpers.manage_rock_stub)
        end
    end
end

return handlers
