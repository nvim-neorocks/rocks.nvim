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
-- luarocks. Installing, uninstalling, updating, etc
--
-------------------------------------------------------------------------------
--
--- Code:

local constants = require("rocks.constants")
local fs = require("rocks.fs")
local config = require("rocks.config")
local state = require("rocks.state")

local operations = {}

function operations.install(name, version, callback)
    -- TODO(vhyrro): Input checking on name and version
    vim.system({ "luarocks", "--lua-version=" .. constants.LUA_VERSION, "--tree=" .. config.rocks_path, "install", name, version }, function(obj)
        callback(obj.code, obj.stderr)
    end)
end

function operations.sync(location)
    -- Read or create a new config file and decode it
    local user_config = require("toml").decode(fs.read_or_create(location or config.config_path, constants.DEFAULT_CONFIG))

    -- Merge `rocks` and `plugins` fields as they are just an eye-candy separator for clarity purposes
    local user_rocks = vim.tbl_deep_extend("force", user_config.rocks, user_config.plugins)

    -- TODO: change this to look for plugins that are not installed yet, also
    -- invoke the update command at the end
    state.installed_rocks(function(rocks)
        local counter = #vim.tbl_keys(rocks)

        if counter == 0 then
            vim.print("Nothing new to install!")
            return
        end

        for name, data in pairs(rocks) do
            operations.install(name, data.version, function(code, err)
                counter = counter - 1

                if code == 0 then
                    vim.print("Successfully updated '" .. name .. "'!")
                else
                    vim.print("Failed to update '" .. name .. "'!")
                    vim.print("Error trace below:")
                    vim.print(err)
                    vim.print("Run :messages for full stacktrace.")
                    return
                end

                if counter == 0 then
                    vim.print("Everything is now in-sync!")
                end
            end)
        end
    end)

    operations.update()
end

function operations.update()
    vim.api.nvim_echo({{"Checking for updates..."}}, false, {})

    state.outdated_rocks(function(rocks)
        local counter = #vim.tbl_keys(rocks)

        if counter == 0 then
            vim.print("Nothing to update!")
            return
        end

        for name, data in pairs(rocks) do
            vim.print("New version for '" .. name .. "': " .. data.version .. " -> " .. data.target_version)

            operations.install(name, data.target_version, function(code, err)
                counter = counter - 1

                if code == 0 then
                    vim.print("Successfully updated '" .. name .. "'!")
                else
                    vim.print("Failed to update '" .. name .. "'!")
                    vim.print("Error trace below:")
                    vim.print(err)
                    vim.print("Run :messages for full stacktrace.")
                    return
                end

                if counter == 0 then
                    vim.print("Everything is now up-to-date!")
                end
            end)
        end
    end)
end

return operations
