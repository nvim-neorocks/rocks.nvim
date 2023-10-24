---@mod rocks.commands rocks.nvim commands
---@brief [[
-- `:Rocks [command [args?]]`
--
-- command	  	                    action
--------------------------------------------------------------------------------------
-- install [package] [version?]  	install rock {package} with {version (optional)}.
-- sync                             synchronize installed rocks with rocks.toml.
-- update                           search for updated rocks and install them.
---@brief ]]
---

-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    24 Oct 2023
-- Updated:    24 Oct 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>

local commands = {}

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

function commands.create_commands()
    vim.api.nvim_create_user_command("Rocks", rocks, {
        nargs = "+",
        desc = "Interacts with currently installed rocks",
        complete = function(arg_lead, cmdline, _)
            local rocks_commands = vim.tbl_keys(rocks_command_tbl)

            if cmdline:match("^Rocks%s+%w*$") then
                return vim.iter(rocks_commands)
                    :filter(function(command)
                        return command:find(arg_lead) ~= nil
                    end)
                    :totable()
            end
        end,
    })
end

return commands
