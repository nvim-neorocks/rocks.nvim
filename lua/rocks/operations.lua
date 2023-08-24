--- operations.lua --- rocks.nvim operations module
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
-- This module handles all the operations that has something to do with
-- luarocks. Installing, uninstalling, updating, etc.
--
-------------------------------------------------------------------------------
--
--- Code:

local constants = require("rocks.constants")
local fs = require("rocks.fs")
local config = require("rocks.config")
local state = require("rocks.state")
local nio = require("nio")

local operations = {}

---@alias Rock {name: string, version: string}
---
operations.install = function(name, version)
    -- TODO(vhyrro): Input checking on name and version
    local future = nio.control.future()
    vim.system(
        {
            "luarocks",
            "--lua-version=" .. constants.LUA_VERSION,
            "--tree=" .. config.rocks_path,
            "install",
            name,
            version,
        },
        {},
        function(...)
            -- TODO: Raise an error with set_error on the future if something goes wrong
            future.set(...)
        end
    )
    return future
end

operations.remove = function(name)
    local future = nio.control.future()
    vim.system(
        { "luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "remove", name },
        {},
        function(...)
            -- TODO: Raise an error with set_error on the future if something goes wrong
            future.set(...)
        end
    )
    return future
end

--- Synchronizes the state inside of rocks.toml with the physical state on the current
--- machine.
---@param user_rocks? { [string]: Rock|string }
---@type fun(user_rocks: { [string]: Rock|string })
operations.sync = function(user_rocks)
    nio.run(function()
        if user_rocks == nil then
            -- Read or create a new config file and decode it
            local user_config = require("toml").decode(fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG))

            -- Merge `rocks` and `plugins` fields as they are just an eye-candy separator for clarity purposes
            user_rocks = vim.tbl_deep_extend("force", user_config.rocks, user_config.plugins)
        end

        for name, data in pairs(user_rocks) do
            -- TODO(vhyrro): Good error checking
            if type(data) == "string" then
                user_rocks[name] = {
                    name = name,
                    version = data,
                }
            end
        end

        local rocks = state.installed_rocks()

        ---@type string[]
        local key_list = nio.fn.uniq(vim.list_extend(vim.tbl_keys(rocks), vim.tbl_keys(user_rocks)))

        local actions = {}

        for _, key in ipairs(key_list) do
            if user_rocks[key] and not rocks[key] then
                table.insert(actions, function()
                    return operations.install(user_rocks[key].name, user_rocks[key].version).wait()
                    -- TODO: After the operation is complete update a UI
                end)
            elseif not user_rocks[key] and rocks[key] then
                table.insert(actions, function()
                    -- NOTE: This will fail if it breaks dependencies.
                    -- That is generall good, although we definitely want a handler
                    -- that ignores this.
                    -- To my knowledge there is no way to query all rocks that are *not*
                    -- dependencies.
                    return operations.remove(rocks[key].name).wait()
                end)
            elseif user_rocks[key].version ~= rocks[key].version then
                table.insert(actions, function()
                    -- TODO: Clean this up?
                    -- `nio.first` seems to cause luarocks to throw some error, look into that.
                    local removed = operations.remove(rocks[key].name).wait()
                    local installed = operations.install(user_rocks[key].name, user_rocks[key].version).wait()
                    return { removed, installed }
                end)
            end
        end

        if not vim.tbl_isempty(actions) then
            -- TODO: Error handling
            local _tasks = nio.gather(actions)
            vim.print("Everything is now in-sync!")
        else
            vim.print("Nothing to synchronize!")
        end
    end)
end

operations.update = function()
    nio.run(function()
        local outdated_rocks = state.outdated_rocks()
        local actions = {}

        for name, rock in pairs(outdated_rocks) do
            table.insert(actions, function()
                return operations.install(name, rock.target_version).wait()
            end)
        end

        if not vim.tbl_isempty(actions) then
            nio.gather(actions)
            vim.print("Update complete!")
        else
            vim.print("Nothing to update!")
        end

        -- TODO: Update the user configuration to reflect the new state.
    end)
end

return operations
