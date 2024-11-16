---@mod rocks.operations.add
--
-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    06 Jul 2024
-- Updated:    06 Jul 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- This module handles the add operation.
--
---@brief ]]

local add = {}

local constants = require("rocks.constants")
local log = require("rocks.log")
local cache = require("rocks.cache")
local helpers = require("rocks.operations.helpers")
local handlers = require("rocks.operations.handlers")
local parser = require("rocks.operations.parser")
local nio = require("nio")
local progress = require("fidget.progress")
local adapter = require("rocks.adapter")

--- Prompt to retry an installation searching the dev manifest, if the version
--- is not "dev" or "scm"
---@param arg_list string[] #Argument list, potentially used by external handlers
---@param rock_name rock_name #The rock name
---@param version? string #The version of the rock to use
---@param skip_prompt? boolean
local function prompt_retry_install_with_dev(arg_list, rock_name, version, skip_prompt)
    if version ~= "dev" then
        local rocks = cache.try_get_rocks()
        local prompt = (
            rocks[rock_name] and rock_name .. " only has a 'dev' version. Install anyway? "
            or "Could not find " .. rock_name .. ". Search for 'dev' version?"
        )
            .. "\n"
            .. "To skip this prompt, run 'Rocks! install {rock}'"
        vim.schedule(function()
            local choice = skip_prompt and 1 or vim.fn.confirm(prompt, "&Yes\n&No", 1, "Question")
            if choice == 1 then
                arg_list = vim.iter(arg_list)
                    :filter(function(arg)
                        -- remove rock_name and version from arg_list
                        return arg:find("=") ~= nil and not vim.startswith(arg, "version=")
                    end)
                    :totable()
                table.insert(arg_list, 1, "dev")
                table.insert(arg_list, 1, rock_name)
                nio.run(function()
                    add.add(arg_list)
                end)
            end
        end)
    end
end

---@class rocks.AddOpts
---@field skip_prompts? boolean Whether to skip any "search 'dev' manifest prompts
---@field cmd? 'install' | 'update' Command used to invoke this function. Default: `'install'`
---@field config_path? string Config file path to use for installing the rock relative to the base config file
---@field callback? fun(rock: Rock) Invoked upon successful completion

--- Adds a new rock and updates the `rocks.toml` file
---@param arg_list string[] #Argument list, potentially used by external handlers. The first argument is the package, e.g. the rock name
---@param opts? rocks.AddOpts
add.add = function(arg_list, opts)
    opts = opts or {}
    opts.cmd = opts.cmd or "install"
    local is_install = opts.cmd == "install"
    local progress_handle = progress.handle.create({
        title = is_install and "Installing" or "Updating",
        lsp_client = { name = constants.ROCKS_NVIM },
    })
    local function report_error(message)
        log.error(("INSTALL ERROR: %s"):format(message))
        progress_handle:report({
            title = "Error",
            message = message,
        })
        progress_handle:cancel()
    end

    nio.run(function()
        helpers.semaphore.with(function()
            local user_rocks = helpers.parse_rocks_toml(opts.config_path)
            local handler = handlers.get_install_handler_callback(user_rocks, arg_list)
            if type(handler) == "function" then
                local function report_progress(message)
                    progress_handle:report({
                        message = message,
                    })
                end
                handler(report_progress, report_error, helpers.manage_rock_stub)
                user_rocks:_write_await()
                nio.scheduler()
                progress_handle:finish()
                return
            end
            ---@type rock_name
            local rock_name = arg_list[1]:lower()
            if #(vim.split(rock_name, "/")) ~= 1 then
                local message = string.format(
                    [[
'Rocks %s' does not support {owner/repo} for luarocks packages.
Use 'Rocks %s {rock_name}' or install rocks-git.nvim.
]],
                    opts.cmd,
                    opts.cmd
                )
                report_error(message)
                return
            end
            -- We can't mutate the arg_list, because we may need it for a recursive add
            ---@type string[]
            local args = #arg_list == 1 and {} or { unpack(arg_list, 2, #arg_list) }
            local parse_result = parser.parse_install_args(args)
            if not vim.tbl_isempty(parse_result.invalid_args) then
                report_error(("invalid %s args: %s"):format(opts.cmd, vim.inspect(parse_result.invalid_args)))
                return
            end
            if not vim.tbl_isempty(parse_result.conflicting_args) then
                report_error(("conflicting %s args: %s"):format(opts.cmd, vim.inspect(parse_result.conflicting_args)))
                return
            end
            local install_spec = parse_result.spec
            local version = install_spec.version
            local breaking_change = not version and helpers.get_breaking_change(rock_name)
            if breaking_change and not helpers.prompt_for_breaking_intall(breaking_change) then
                progress_handle:report({
                    title = string.format("%s aborted", is_install and "Installation" or "Update"),
                })
                progress_handle:cancel()
            end
            nio.scheduler()
            progress_handle:report({
                message = version and ("%s -> %s"):format(rock_name, version) or rock_name,
            })
            ---@type RockSpec
            local rock_spec = {
                name = rock_name,
                version = version,
            }
            local future = helpers.install(rock_spec)
            ---@type boolean, Rock | string
            local success, installed_rock = pcall(future.wait)
            if not success then
                local stderr = installed_rock
                ---@cast stderr string
                local not_found = stderr:match("No results matching query were found") ~= nil
                local message = ("%s %s failed. Run ':Rocks log' for details."):format(
                    is_install and "Installing" or "Updating",
                    rock_name
                )
                if not_found then
                    message = ("Could not find %s %s"):format(rock_name, version or "")
                end
                nio.scheduler()
                progress_handle:report({
                    title = ("%s failed"):format(is_install and "Installation" or "Update"),
                    message = message,
                })
                if not_found then
                    prompt_retry_install_with_dev(arg_list, rock_name, version, opts.skip_prompts)
                end
                nio.scheduler()
                progress_handle:cancel()
                return
            end
            adapter.synchronise_site_symlinks()
            helpers.dynamic_load(rock_spec).wait()
            ---@cast installed_rock Rock
            nio.scheduler()
            progress_handle:report({
                title = ("%s successful"):format(is_install and "Installation" or "Update"),
                message = ("%s -> %s"):format(installed_rock.name, installed_rock.version),
                percentage = 100,
            })
            -- FIXME(vhyrro): This currently works in a half-baked way.
            -- The `toml-edit` libary will create a new empty table here, but if you were to try
            -- and populate the table upfront then none of the values will be registered by `toml-edit`.
            -- This should be fixed ASAP.
            if not user_rocks.plugins then
                local plugins = vim.empty_dict()
                user_rocks.plugins = plugins
            end

            -- Set installed version as `scm` if development version has been installed
            if version == "dev" then
                installed_rock.version = "scm"
            end
            local user_rock = user_rocks.plugins[rock_name]
            if user_rock and user_rock.version then
                -- Rock already exists in rock.toml and is configured as a table -> Update version.
                user_rocks.plugins[rock_name].version = installed_rock.version
                for _, field in ipairs({ "opt", "pin" }) do
                    if install_spec[field] then
                        user_rocks.plugins[rock_name][field] = true
                    elseif user_rocks.plugins[rock_name][field] then
                        user_rocks.plugins[rock_name][field] = nil
                    end
                end
            elseif install_spec.opt or install_spec.pin then
                -- toml-edit's metatable can't set a table directly.
                -- Each field has to be set individually.
                ---@diagnostic disable-next-line: missing-fields
                user_rocks.plugins[rock_name] = {}
                user_rocks.plugins[rock_name].version = installed_rock.version
                user_rocks.plugins[rock_name].opt = install_spec.opt
                user_rocks.plugins[rock_name].pin = install_spec.pin
            else
                user_rocks.plugins[rock_name] = installed_rock.version
            end
            user_rocks:_write_await()
            cache.populate_all_rocks_state_caches()
            vim.schedule(function()
                helpers.postInstall()
                if success then
                    progress_handle:finish()
                    if opts.callback then
                        opts.callback(installed_rock)
                    end
                else
                    progress_handle:cancel()
                end
            end)
        end)
    end)
end

return add
