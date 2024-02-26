---@mod rocks.commands rocks.nvim commands
---
---@brief [[
---
--- `:Rocks[!] {command {args?}}`
---
--- command	  	                     action
---------------------------------------------------------------------------------
---
--- install {rock} {version?}  	     Install {rock} with optional {version}.
--- prune {rock}                     Uninstall {rock} and its stale dependencies,
---                                  and remove it from rocks.toml.
--- sync                             Synchronize installed rocks with rocks.toml.
---                                  It may take more than one sync to prune all rocks that can be pruned.
--- update                           Search for updated rocks and install them.
--- edit                             Edit the rocks.toml file.
--- packadd {rock}                   Search for an optional rock and source any plugin files found.
---                                  The rock must be installed by luarocks.
---                                  It is added to the 'runtimepath' if it wasn't there yet.
---                                  If `Rocks` is called with the optional `!`, the rock is added
---                                  to the |runtimepath| and no |plugin| or |ftdetect| scripts are
---                                  sourced.
---                                  This command aims to behave similarly to the builtin |packadd|,
---                                  and will fall back to it if no rock is found.
---                                  To make a rock optional, set `opt = true` in `rocks.toml`.
--- log                              Open the log file.
---
---@brief ]]
---

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    24 Oct 2023
-- Updated:    24 Oct 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>

local commands = {}

local fzy = require("rocks.fzy")
local cache = require("rocks.cache")
local fs = require("rocks.fs")
local constants = require("rocks.constants")

---@param name string
---@param query string | nil
---@return string[]
local function complete_versions(name, query)
    local rocks = cache.try_get_rocks()[name] or vim.empty_dict()
    local matching_rocks = vim.tbl_filter(function(rock)
        ---@cast rock Rock
        if not query then
            return true
        end
        return rock.name == name and vim.startswith(rock.version, query)
    end, rocks)
    local unique_versions = {}
    for _, rock in pairs(matching_rocks) do
        unique_versions[rock.version] = rock
    end

    local unique_keys = vim.tbl_keys(unique_versions)
    table.sort(unique_keys, function(a, b)
        return a > b
    end)
    return unique_keys
end

---@param query string | nil
---@return string[]
local function complete_names(query)
    local rocks = cache.try_get_rocks()
    if not query then
        return {}
    end
    local rock_names = vim.tbl_keys(rocks)
    return fzy.fuzzy_filter(query, rock_names)
end

---Completion for installed rocks that are not dependencies of other rocks
---and can be removed.
---@param query string | nil
---@return string[]
local function complete_removable_rocks(query)
    local removable_rocks = cache.try_get_removable_rocks()
    if not query then
        return {}
    end
    return fzy.fuzzy_filter(query, removable_rocks)
end

---@type { [string]: RocksCmd }
local rocks_command_tbl = {
    update = {
        impl = function(_)
            require("rocks.operations").update()
        end,
    },
    sync = {
        impl = function(_)
            require("rocks.operations").sync()
        end,
    },
    install = {
        impl = function(args)
            if #args == 0 then
                vim.notify("Rocks install: Called without required package argument.", vim.log.levels.ERROR)
                return
            end
            local package, version = args[1], args[2]
            require("rocks.operations").add(args, package, version)
        end,
        complete = function(query)
            local name, version_query = query:match("([^%s]+)%s(.+)$")
            -- name followed by space, but no version?
            name = name or query:match("([^%s]+)%s$")
            if version_query or name then
                local version_list = complete_versions(name, version_query)
                if #version_list > 0 then
                    return version_list
                end
            end
            local name_query = query:match("(.*)$")
            return complete_names(name_query)
        end,
    },
    prune = {
        impl = function(args)
            if #args == 0 then
                vim.notify("Rocks prune: Called without required package argument.", vim.log.levels.ERROR)
                return
            end
            local package = args[1]
            require("rocks.operations").prune(package)
        end,
        complete = function(query)
            local rocks_list = complete_removable_rocks(query)
            return rocks_list
        end,
    },
    edit = {
        impl = function(_)
            local config_path = require("rocks.config.internal").config_path
            if not fs.file_exists(config_path) then
                fs.write_file(config_path, "w+", vim.trim(constants.DEFAULT_CONFIG))
            end
            vim.cmd.e(config_path)
        end,
    },
    packadd = {
        impl = function(args, opts)
            if #args ~= 1 then
                vim.notify("Rocks packadd: Called without required rock argument.", vim.log.levels.ERROR)
                return
            end
            local rock_name = args[1]
            require("rocks.runtime").packadd(rock_name, { bang = opts.bang })
        end,
        complete = function(query)
            return require("rocks.runtime").complete_packadd(query)
        end,
    },
    log = {
        impl = function(_)
            require("rocks.log").open_logfile()
        end,
    },
}

local function rocks(opts)
    local fargs = opts.fargs
    local cmd = fargs[1]
    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local command = rocks_command_tbl[cmd]
    if not command then
        vim.notify("Rocks: Unknown command: " .. cmd, vim.log.levels.ERROR)
        return
    end
    command.impl(args, opts)
end

---@package
function commands.create_commands()
    vim.api.nvim_create_user_command("Rocks", rocks, {
        nargs = "+",
        desc = "Interacts with currently installed rocks",
        complete = function(arg_lead, cmdline, _)
            local rocks_commands = vim.tbl_keys(rocks_command_tbl)
            local subcmd, subcmd_arg_lead = cmdline:match("^Rocks[!]*%s(%S+)%s(.*)$")
            if subcmd and subcmd_arg_lead and rocks_command_tbl[subcmd] and rocks_command_tbl[subcmd].complete then
                return rocks_command_tbl[subcmd].complete(subcmd_arg_lead)
            end
            if cmdline:match("^Rocks[!]*%s+%w*$") then
                return fzy.fuzzy_filter(arg_lead, rocks_commands)
            end
        end,
        bang = true,
    })
end

---@param name string The name of the subcommand
---@param cmd RocksCmd The implementation and optional completions
---@package
function commands.register_subcommand(name, cmd)
    vim.validate({ name = { name, "string" } })
    vim.validate({ impl = { cmd.impl, "function" }, complete = { cmd.complete, "function", true } })
    rocks_command_tbl[name] = cmd
end

return commands
