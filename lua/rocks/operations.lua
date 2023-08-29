--- operations.lua --- rocks.nvim operations module
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
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
    vim.system({
        "luarocks",
        "--lua-version=" .. constants.LUA_VERSION,
        "--tree=" .. config.rocks_path,
        "install",
        name,
        version,
    }, {}, function(...)
        -- TODO: Raise an error with set_error on the future if something goes wrong
        future.set(...)
    end)
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

        local Split = require("nui.split")
        local NuiText = require("nui.text")

        local rocks = state.installed_rocks()

        ---@type string[]
        local key_list = nio.fn.uniq(vim.list_extend(vim.tbl_keys(rocks), vim.tbl_keys(user_rocks)))

        local actions = {}

        local split = Split({
            relative = "editor",
            position = "right",
            size = "33%",
        })

        for i = 1, #key_list do
            vim.api.nvim_buf_set_lines(split.bufnr, i, i, true, { "" })
        end

        local linenr = 1

        for _, key in ipairs(key_list) do
            local linenr_copy = linenr

            if user_rocks[key] and not rocks[key] then
                local text = NuiText("Installing '" .. key .. "'")
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, text:content():len())

                table.insert(actions, function()
                    local ret = operations.install(user_rocks[key].name, user_rocks[key].version).wait()

                    nio.scheduler()
                    text:set("Installed '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, text:content():len())

                    return ret
                end)
            elseif not user_rocks[key] and rocks[key] then
                local text = NuiText("Removing '" .. key .. "'")
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, text:content():len())

                table.insert(actions, function()
                    -- NOTE: This will fail if it breaks dependencies.
                    -- That is generally good, although we definitely want a handler
                    -- that ignores this.
                    -- To my knowledge there is no way to query all rocks that are *not*
                    -- dependencies.
                    local ret = operations.remove(rocks[key].name).wait()

                    nio.scheduler()
                    text:set("Removed '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, text:content():len())

                    return ret
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

            linenr = linenr + 1
        end

        if not vim.tbl_isempty(actions) then
            split:mount()
            -- TODO: Error handling
            nio.gather(actions)
        else
            split:unmount()
        end
    end)
end

--- Attempts to update every available plugin if it is not pinned.
--- This function invokes a UI.
operations.update = function()
    require("nio").run(function()
        local Split = require("nui.split")
        local NuiText = require("nui.text")

        local outdated_rocks = state.outdated_rocks()
        local actions = {}

        nio.scheduler()

        local split = Split({
            relative = "editor",
            position = "right",
            size = "33%",
        })

        for i = 1, vim.tbl_count(outdated_rocks) - 1 do
            vim.api.nvim_buf_set_lines(split.bufnr, i, i, true, { "" })
        end

        local linenr = 1

        for name, rock in pairs(outdated_rocks) do
            local display_text = "Updating '" .. name .. "'"
            local text = NuiText(display_text)
            local linenr_copy = linenr

            text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, display_text:len())

            table.insert(actions, function()
                local ret = operations.install(name, rock.target_version).wait()
                nio.scheduler()
                text:set("Updated '" .. name .. "'")
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, display_text:len())
                return ret
            end)

            linenr = linenr + 1
        end

        if not vim.tbl_isempty(actions) then
            split:mount()
            nio.gather(actions)
        else
            split:unmount()
            vim.notify("Nothing to update!")
        end
    end)
end

return operations
