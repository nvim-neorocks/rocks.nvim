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
    }, {}, function(obj)
        if obj.code ~= 0 then
            future.set_error(obj.stderr)
        else
            future.set({
                name = name,
                version = obj.stdout:match(name .. "%s+(%d+%.%d+%.%d+%-%d+)"),
            })
        end
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

        -- The following code uses `nio.fn.keys` instead of `vim.tbl_keys`
        -- which invokes the scheduler and works in async contexts.
        ---@type string[]
        local key_list = nio.fn.keys(vim.tbl_deep_extend("force", rocks, user_rocks))

        local actions = {}

        local split = Split({
            relative = "editor",
            position = "right",
            size = "33%",
        })

        local line_nr = 1

        for _, key in ipairs(key_list) do
            local linenr_copy = line_nr
            local expand_ui = true

            if user_rocks[key] and not rocks[key] then
                local text = NuiText("Installing '" .. key .. "'")
                local msg_length = text:content():len()
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                table.insert(actions, function()
                    local ret = operations.install(user_rocks[key].name, user_rocks[key].version).wait()

                    nio.scheduler()
                    text:set("Installed '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                    return ret
                end)
            elseif not user_rocks[key] and rocks[key] then
                local text = NuiText("Removing '" .. key .. "'")
                local msg_length = text:content():len()
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                table.insert(actions, function()
                    -- NOTE: This will fail if it breaks dependencies.
                    -- That is generally good, although we definitely want a handler
                    -- that ignores this.
                    -- To my knowledge there is no way to query all rocks that are *not*
                    -- dependencies.
                    local ret = operations.remove(rocks[key].name).wait()

                    nio.scheduler()
                    text:set("Removed '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                    return ret
                end)
            elseif user_rocks[key].version ~= rocks[key].version then
                local is_downgrading = vim.version.parse(user_rocks[key].version)
                    < vim.version.parse(rocks[key].version)

                local text = NuiText((is_downgrading and "Downgrading" or "Updating") .. " '" .. key .. "'")
                local msg_length = text:content():len()
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                table.insert(actions, function()
                    local ret = operations.install(user_rocks[key].name, user_rocks[key].version).wait()

                    nio.scheduler()
                    text:set((is_downgrading and "Downgraded" or "Updated") .. " '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                    return ret
                end)
            else
                expand_ui = false
            end

            if expand_ui and line_nr >= 1 then
                vim.api.nvim_buf_set_lines(split.bufnr, line_nr, line_nr, true, { "" })
                line_nr = line_nr + 1
            end
        end

        if not vim.tbl_isempty(actions) then
            split:mount()
            -- TODO: Error handling
            nio.gather(actions)
        else
            split:unmount()
            vim.notify("Everything is in-sync!")
        end
    end)
end

--- Attempts to update every available plugin if it is not pinned.
--- This function invokes a UI.
operations.update = function()
    nio.run(function()
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

--- Adds a new rock and updates the `rocks.toml` file
---@param rock_name string #The rock name
---@param version? string #The version of the rock to use
operations.add = function(rock_name, version)
    vim.notify("Installing '" .. rock_name .. "'...")

    nio.run(function()
        local installed_rock = operations.install(rock_name, version).wait()
        vim.schedule(function()
            local user_rocks =
                require("toml_edit").parse(fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG))
            -- FIXME(vhyrro): This currently works in a half-baked way.
            -- The `toml-edit` libary will create a new empty table here, but if you were to try
            -- and populate the table upfront then none of the values will be registered by `toml-edit`.
            -- This should be fixed ASAP.
            if not user_rocks.plugins then
                user_rocks.plugins = {}
            end

            user_rocks.plugins[installed_rock.name] = installed_rock.version
            fs.write_file(config.config_path, "w", tostring(user_rocks))
            vim.notify("Installation successful: " .. installed_rock.name .. " -> " .. installed_rock.version)
        end)
    end)
end

return operations
