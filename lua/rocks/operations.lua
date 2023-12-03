---@mod rocks.operations
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
--
---@brief [[
--
-- This module handles all the operations that has something to do with
-- luarocks. Installing, uninstalling, updating, etc.
--
---@brief ]]

local constants = require("rocks.constants")
local fs = require("rocks.fs")
local config = require("rocks.config.internal")
local state = require("rocks.state")
local luarocks = require("rocks.luarocks")
local nio = require("nio")

local operations = {}

---@class (exact) Future
---@field wait fun() Wait in an async context. Does not block in a sync context
---@field wait_sync fun() Wait in a sync context

---@param name string
---@param version? string
---@return Future
operations.install = function(name, version)
    state.invalidate_cache()
    -- TODO(vhyrro): Input checking on name and version
    local future = nio.control.future()
    local install_cmd = {
        "install",
        name,
    }
    if version then
        -- If specified version is dev then install the `scm-1` version of the rock
        if version == "dev" then
            table.insert(install_cmd, 2, "--dev")
        else
            table.insert(install_cmd, version)
        end
    end
    local systemObj = luarocks.cli(install_cmd, function(obj)
        if obj.code ~= 0 then
            future.set_error(obj.stderr)
        else
            future.set({
                name = name,
                -- The `gsub` makes sure to escape all punctuation characters
                -- so they do not get misinterpeted by the lua pattern engine.
                version = obj.stdout:match(name:gsub("%p", "%%%1") .. "%s+(%S+)"),
            })
        end
    end)
    return {
        wait = future.wait,
        wait_sync = function()
            systemObj:wait()
        end,
    }
end

---Removes a rock
---@param name string
---@return Future
operations.remove = function(name)
    state.invalidate_cache()
    local future = nio.control.future()
    local systemObj = luarocks.cli({
        "remove",
        name,
    }, function(...)
        -- TODO: Raise an error with set_error on the future if something goes wrong
        future.set(...)
    end)
    return {
        wait = future.wait,
        wait_sync = function()
            systemObj:wait()
        end,
    }
end

---Removes a rock, and recursively removes its dependencies
---if they are no longer needed.
---@type fun(name: string)
operations.remove_recursive = nio.create(function(name)
    ---@cast name string
    local dependencies = state.rock_dependencies(name)
    operations.remove(name).wait()
    local removable_rocks = state.query_removable_rocks()
    for _, dep in pairs(dependencies) do
        if vim.list_contains(removable_rocks, dep.name) then
            operations.remove_recursive(dep.name)
        end
    end
end)

--- Synchronizes the user rocks with the physical state on the current machine.
--- - Installs missing rocks
--- - Ensures that the correct versions are installed
--- - Uninstalls unneeded rocks
---@param user_rocks? { [string]: Rock|string } loaded from rocks.toml if `nil`
operations.sync = function(user_rocks)
    nio.run(function()
        if user_rocks == nil then
            -- Read or create a new config file and decode it
            local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
            local user_config = require("toml").decode(config_file)

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

        local installed_rocks = state.installed_rocks()

        -- The following code uses `nio.fn.keys` instead of `vim.tbl_keys`
        -- which invokes the scheduler and works in async contexts.
        ---@type string[]
        ---@diagnostic disable-next-line: invisible
        local key_list = nio.fn.keys(vim.tbl_deep_extend("force", installed_rocks, user_rocks))

        ---@type (fun():any)[]
        local actions = {}

        local split = Split({
            relative = "editor",
            position = "right",
            size = "40%",
        })

        local line_nr = 1

        ---@type {[string]: RockDependency}
        local dependencies = {}

        ---@type string[]
        local to_remove_keys = {}

        for _, key in ipairs(key_list) do
            local linenr_copy = line_nr
            local expand_ui = true

            if user_rocks[key] and not installed_rocks[key] then
                local text = NuiText("Installing '" .. key .. "'")
                local msg_length = text:content():len()
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                table.insert(actions, function()
                    -- If the plugin version is a development release then we pass `dev` as the version to the install function
                    -- as it gets converted to the `--dev` flag on there, allowing luarocks to pull the `scm-1` rockspec manifest
                    local ret
                    if vim.startswith(user_rocks[key].version, "scm-") then
                        ret = operations.install(user_rocks[key].name, "dev").wait()
                    else
                        ret = operations.install(user_rocks[key].name, user_rocks[key].version).wait()
                    end

                    nio.scheduler()
                    text:set("Installed '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                    return ret
                end)
            elseif
                user_rocks[key]
                and installed_rocks[key]
                and user_rocks[key].version ~= installed_rocks[key].version
            then
                local is_downgrading = vim.version.parse(user_rocks[key].version)
                    < vim.version.parse(installed_rocks[key].version)

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
            elseif not user_rocks[key] and installed_rocks[key] then
                table.insert(to_remove_keys, key)
                expand_ui = false
            else
                expand_ui = false
            end

            if installed_rocks[key] then
                -- NOTE(vhyrro): It is not possible to use the vim.tbl_extend or vim.tbl_deep_extend
                -- functions here within the async context. It simply refuses to work.
                for k, v in pairs(state.rock_dependencies(installed_rocks[key])) do
                    dependencies[k] = v
                end
            end

            if expand_ui and line_nr >= 1 then
                nio.scheduler()
                vim.api.nvim_buf_set_lines(split.bufnr, line_nr, line_nr, true, { "" })
                line_nr = line_nr + 1
            end
        end

        for _, key in ipairs(to_remove_keys) do
            local linenr_copy = line_nr
            local is_dependency = dependencies[key] ~= nil
            local expand_ui = not is_dependency

            if not is_dependency then
                nio.scheduler()
                local text = NuiText("Removing '" .. key .. "'")
                local msg_length = text:content():len()
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                table.insert(actions, function()
                    local ret = operations.remove(installed_rocks[key].name).wait()

                    nio.scheduler()
                    text:set("Removed '" .. key .. "'")
                    text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, msg_length)

                    return ret
                end)
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

--- Attempts to update every available rock if it is not pinned.
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
            size = "40%",
        })

        for i = 1, vim.tbl_count(outdated_rocks) - 1 do
            vim.api.nvim_buf_set_lines(split.bufnr, i, i, true, { "" })
        end

        local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
        local user_rocks = require("toml_edit").parse(config_file)
        local linenr = 1

        for name, rock in pairs(outdated_rocks) do
            local display_text = "Updating '" .. name .. "'"
            local text = NuiText(display_text)
            local linenr_copy = linenr

            text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, display_text:len())

            table.insert(actions, function()
                local ret = operations.install(name, rock.target_version).wait()
                user_rocks.plugins[ret.name] = ret.version
                nio.scheduler()
                text:set("Updated '" .. name .. "' to " .. rock.target_version)
                text:render_char(split.bufnr, -1, linenr_copy, 0, linenr_copy, display_text:len())
            end)

            linenr = linenr + 1
        end

        if not vim.tbl_isempty(actions) then
            split:mount()
            nio.gather(actions)
            fs.write_file(config.config_path, "w", tostring(user_rocks))
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
            local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
            local user_rocks = require("toml_edit").parse(config_file)
            -- FIXME(vhyrro): This currently works in a half-baked way.
            -- The `toml-edit` libary will create a new empty table here, but if you were to try
            -- and populate the table upfront then none of the values will be registered by `toml-edit`.
            -- This should be fixed ASAP.
            if not user_rocks.plugins then
                user_rocks.plugins = {}
            end

            -- Set installed version as `scm-1` if development version has been installed
            if version == "dev" then
                installed_rock.version = "scm-1"
            end
            user_rocks.plugins[installed_rock.name] = installed_rock.version
            fs.write_file(config.config_path, "w", tostring(user_rocks))
            vim.notify("Installation successful: " .. installed_rock.name .. " -> " .. installed_rock.version)
        end)
    end)
end

---Uninstall a rock, pruning it from rocks.toml.
---@param rock_name string
operations.prune = function(rock_name)
    vim.notify("Uninstalling '" .. rock_name .. "'...")
    nio.run(function()
        -- TODO: Error handling
        operations.remove_recursive(rock_name)
        vim.schedule(function()
            local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
            local user_rocks = require("toml_edit").parse(config_file)
            if not user_rocks.plugins then
                return
            end
            user_rocks.plugins[rock_name] = nil
            fs.write_file(config.config_path, "w", tostring(user_rocks))
            vim.notify("Uninstalled: " .. rock_name)
        end)
    end)
end

return operations
