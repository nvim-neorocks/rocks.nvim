---@mod rocks.commands rocks.nvim commands
---
---@brief [[
---
--- `:Rocks [command [args?]]`
---
--- command	  	                     action
---------------------------------------------------------------------------------
---
--- install [rock] [version?]  	     install {rock} with optional {version}.
--- prune [rock]                     uninstall {rock} and its stale dependencies,
---                                  and remove it from rocks.toml.
--- sync                             synchronize installed rocks with rocks.toml.
--- update                           search for updated rocks and install them.
--- edit                             edit the rocks.toml file.
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
    return fzy.fuzzy_filter_sort(query, rock_names)
end

---@type { [string]: fun(args:string[]) }
local rocks_command_tbl = {
    update = function(_)
        require("rocks.operations").update()
    end,
    sync = function(_)
        require("rocks.operations").sync()
    end,
    install = function(args)
        if #args == 0 then
            vim.notify("Rocks install: Called without required package argument.", vim.log.levels.ERROR)
            return
        end
        local package, version = args[1], args[2]
        require("rocks.operations").add(package, version)
    end,
    prune = function(args)
        if #args == 0 then
            vim.notify("Rocks prune: Called without required package argument.", vim.log.levels.ERROR)
            return
        end
        local package = args[1]
        require("rocks.operations").prune(package)
    end,
    edit = function(_)
        vim.cmd.e(require("rocks.config.internal").config_path)
    end,
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
    command(args)
end

---@package
function commands.create_commands()
    vim.api.nvim_create_user_command("Rocks", rocks, {
        nargs = "+",
        desc = "Interacts with currently installed rocks",
        complete = function(arg_lead, cmdline, _)
            local rocks_commands = vim.tbl_keys(rocks_command_tbl)

            local name, version_query = cmdline:match("^Rocks install%s([^%s]+)%s(.+)$")
            -- name followed by space, but no version?
            name = name or cmdline:match("^Rocks install%s([^%s]+)%s$")
            if version_query or name then
                local version_list = complete_versions(name, version_query)
                if #version_list > 0 then
                    return version_list
                end
            end
            local name_query = cmdline:match("^Rocks install%s(.*)$")
            local rocks_list = complete_names(name_query)
            if #rocks_list > 0 then
                return rocks_list
            end
            local state = require("rocks.state")
            name_query = cmdline:match("^Rocks prune%s(.*)$")
            rocks_list = state.complete_removable_rocks(name_query)
            if #rocks_list > 0 then
                return rocks_list
            end
            if cmdline:match("^Rocks%s+%w*$") then
                return fzy.fuzzy_filter_sort(arg_lead, rocks_commands)
            end
        end,
    })
end

return commands
