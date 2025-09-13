---@mod lux-commands lux.nvim commands
---
---@brief [[
---
--- `:Lux[!] {command {args?}}`
---
--- command	  	                     action
---------------------------------------------------------------------------------
---
--- install {package} {version?} {args[]?} Install {package} with optional {version} and optional {args[]}.
---                                        Example: ':Lux install neorg 8.0.0 opt=true'
---                                        Will install or update to the latest version if called
---                                        without {version}.
---                                        args (optional):
---                                          - opt={true|false}
---                                            Packages that have been installed with 'opt=true'
---                                            can be sourced with |packadd|.
---                                          - pin={true|false}
---                                            Packages that have been installed with 'pin=true'
---                                            will be ignored by ':Lux update'.
---                                        Use 'Lux! install ...' to skip prompts.
--- prune {package}                        Uninstall {package} and its stale dependencies,
---                                        and remove it from lux.toml.
--- sync                                   Synchronize installed packages with lux.toml.
---                                        It may take more than one sync to prune all packages that can be pruned.
--- update {package?}                      Search for updated packages and install them.
---                                        If called with the optional {packages} argument, only {packages}
---                                        will be updated.
---                                        Use 'Lux! update` to skip prompts.
---                                        with breaking changes.
--- edit                                   Edit the lux.toml file.
--- pin {package}                          Pin {package} to the installed version.
---                                        Pinned packages are ignored by ':Lux update'.
--- unpin {package}                        Unpin {package}.
--- log                                    Open the log file.
---
---@brief ]]
---

local commands = {}

local fzy = require("lux-nvim.fzy")

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
        if rock.version == "scm" then
            rock.version = "dev"
        end
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

---@param predicate fun(spec: RockSpec):boolean
---@param query string
---@return rock_name[]
local function fuzzy_filter_user_rocks(predicate, query)
    local user_rocks = config.get_user_rocks()
    if vim.tbl_isempty(user_rocks) then
        return {}
    end
    ---@type rock_name[]
    local rock_names = vim.iter(vim.fn.values(user_rocks))
        :filter(predicate)
        :map(function(spec)
            ---@cast spec RockSpec
            return spec.name
        end)
        :totable()
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
        impl = function(args, opts)
            if #args == 0 then
                require("lux-nvim.operations").update(nil, {
                    skip_prompts = opts.bang,
                })
            elseif #args == 1 then
                local rock_name = args[1]
                local user_rocks = config.get_user_rocks()
                local rock = user_rocks[rock_name]
                if not rock then
                    vim.notify(("lux-nvim update: %s is not installed"):format(rock_name), vim.log.levels.ERROR)
                    return
                elseif rock.version == "dev" or rock.version == "scm" then
                    -- Skip "rock not found" prompt
                    table.insert(args, rock.version)
                end
                require("lux-nvim.operations").add(args, {
                    skip_prompts = opts.bang,
                    cmd = "update",
                })
            else
                vim.notify("lux-nvim update: Too many arguments: " .. vim.inspect(args), vim.log.levels.ERROR)
            end
        end,
        complete = function(query)
            local outdated_rocks = cache.try_get_outdated_rocks()
            ---@param spec RockSpec
            return fuzzy_filter_user_rocks(function(spec)
                return outdated_rocks[spec.name] ~= nil or spec.version == "dev" or spec.version == "scm"
            end, query)
        end,
    },
    sync = {
        impl = function(_)
            require("lux-nvim.operations").sync()
        end,
    },
    install = {
        impl = function(args, opts)
            if #args == 0 then
                vim.notify("lux-nvim install: Called without required package argument.", vim.log.levels.ERROR)
                return
            end
            require("lux-nvim.operations").add(args, {
                skip_prompts = opts.bang,
            })
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
                vim.notify("lux-nvim prune: Called without required package argument.", vim.log.levels.ERROR)
                return
            end
            local package = args[1]
            require("lux-nvim.operations").prune(package)
        end,
        complete = function(query)
            local rocks_list = complete_removable_rocks(query)
            return rocks_list
        end,
    },
    edit = {
        impl = function(_)
            local config_path = require("lux-nvim.config.internal").config_path
            if fs.file_exists(config_path) then
                vim.cmd.e(config_path)
            else
                fs.write_file(config_path, "w+", vim.trim(constants.DEFAULT_CONFIG), function()
                    vim.cmd.e(config_path)
                end)
            end
        end,
    },
    pin = {
        impl = function(args)
            local rock_name = args[1]
            if not rock_name then
                vim.notify("'pin {rock}: Missing argument {rock}", vim.log.levels.ERROR)
                return
            end
            require("lux-nvim.operations").pin(rock_name)
        end,
        complete = function(query)
            ---@param spec RockSpec
            return fuzzy_filter_user_rocks(function(spec)
                ---@cast spec RockSpec
                return not spec.pin
            end, query)
        end,
    },
    unpin = {
        impl = function(args)
            local rock_name = args[1]
            if not rock_name then
                vim.notify("'pin {rock}: Missing argument {rock}", vim.log.levels.ERROR)
                return
            end
            require("lux-nvim.operations").unpin(rock_name)
        end,
        complete = function(query)
            ---@param spec RockSpec
            return fuzzy_filter_user_rocks(function(spec)
                ---@cast spec RockSpec
                return spec.pin
            end, query)
        end,
    },
    packadd = {
        impl = function(args, opts)
            if #args ~= 1 then
                vim.notify("lux-nvim packadd: Called without required rock argument.", vim.log.levels.ERROR)
                return
            end
            local rock_name = args[1]
            require("lux-nvim").packadd(rock_name, { bang = opts.bang })
        end,
    },
    log = {
        impl = function(_)
            require("lux-nvim.log").open_logfile()
        end,
    },
}

local function rocks(opts)
    local fargs = opts.fargs
    local cmd = fargs[1]
    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local command = rocks_command_tbl[cmd]
    if not command then
        vim.notify("lux-nvim: Unknown command: " .. cmd, vim.log.levels.ERROR)
        return
    end
    command.impl(args, opts)
end

---@package
function commands.create_commands()
    log.trace("Creating commands")
    vim.api.nvim_create_user_command("Lux", rocks, {
        nargs = "+",
        desc = "Interacts with currently installed rocks",
        complete = function(arg_lead, cmdline, _)
            local rocks_commands = vim.iter(vim.tbl_keys(rocks_command_tbl))
                :filter(function(subcmd)
                    return subcmd ~= "packadd"
                end)
                :totable()
            local subcmd, subcmd_arg_lead = cmdline:match("^Lux[!]*%s(%S+)%s(.*)$")
            if subcmd and subcmd_arg_lead and rocks_command_tbl[subcmd] and rocks_command_tbl[subcmd].complete then
                return rocks_command_tbl[subcmd].complete(subcmd_arg_lead)
            end
            if cmdline:match("^Lux[!]*%s+%w*$") then
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
