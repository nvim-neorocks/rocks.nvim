---@mod rocks.operations.update
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
-- This module handles the update operation.
--
---@brief ]]

local update = {}

local constants = require("rocks.constants")
local log = require("rocks.log")
local fs = require("rocks.fs")
local config = require("rocks.config.internal")
local state = require("rocks.state")
local cache = require("rocks.cache")
local helpers = require("rocks.operations.helpers")
local handlers = require("rocks.operations.handlers")
local nio = require("nio")
local progress = require("fidget.progress")

---@param outdated_rocks table<rock_name, OutdatedRock>
---@return table<rock_name, OutdatedRock>
local function add_dev_rocks_for_update(outdated_rocks)
    return vim.iter(config.get_user_rocks()):fold(outdated_rocks, function(acc, name, spec)
        ---@cast acc table<rock_name, OutdatedRock>
        ---@cast name rock_name
        ---@cast spec RockSpec
        if spec.version == "scm" then
            acc[name] = {
                name = spec.name,
                version = spec.version,
                target_version = spec.version,
            }
        end
        return acc
    end)
end

---@class rocks.UpdateOpts
---@field skip_prompts? boolean Whether to skip "install breaking changes?" prompts

--- Attempts to update every available rock if it is not pinned.
--- This function invokes a UI.
---@param on_complete? function
---@param opts? rocks.UpdateOpts
update.update = function(on_complete, opts)
    opts = opts or {}
    local progress_handle = progress.handle.create({
        title = "Updating",
        message = "Checking for updates...",
        lsp_client = { name = constants.ROCKS_NVIM },
        percentage = 0,
    })

    nio.run(function()
        helpers.semaphore.with(function()
            ---@type ProgressHandle[]
            local error_handles = {}
            ---@param message string
            local function report_error(message)
                log.error(("UPDATE ERROR: %s"):format(message))
                table.insert(
                    error_handles,
                    progress.handle.create({
                        title = "Error",
                        lsp_client = { name = constants.ROCKS_NVIM },
                        message = message,
                    })
                )
            end

            local user_rocks = helpers.parse_rocks_toml()

            local to_update = vim.iter(state.outdated_rocks()):fold(
                {},
                -- Filter unpinned rocks
                ---@param acc table<rock_name, OutdatedRock>
                ---@param key rock_name
                ---@param rock OutdatedRock
                function(acc, key, rock)
                    local _, user_rock = helpers.get_rock_and_key(user_rocks, rock.name)
                    if user_rock and not user_rock.pin then
                        acc[key] = rock
                    end
                    return acc
                end
            )

            local breaking_changes = helpers.get_breaking_changes(to_update)
            if not opts.skip_prompts and not vim.tbl_isempty(breaking_changes) then
                to_update = helpers.prompt_for_breaking_update(breaking_changes, to_update)
            end
            if config.reinstall_dev_rocks_on_update then
                to_update = add_dev_rocks_for_update(to_update)
            end
            local external_update_handlers = handlers.get_update_handler_callbacks(user_rocks)

            local update_summary_tbl = vim
                .iter(to_update)
                ---@param rock OutdatedRock
                :map(function(_, rock)
                    return ("%s %s -> %s"):format(rock.name, rock.version, rock.target_version)
                end)
                :totable()
            local update_summary = table.concat(update_summary_tbl, "\n")

            nio.scheduler()
            progress_handle:report({
                message = update_summary,
            })
            -- Update dependencies sequentially first
            for name, rock in pairs(to_update) do
                local future = helpers.install({
                    name = name,
                    version = rock.target_version,
                }, {
                    only_deps = true,
                })
                local success = pcall(future.wait)
                if not success then
                    nio.scheduler()
                    report_error(("Failed to update %s."):format(rock.name))
                end
            end
            -- Then update rocks concurrently
            ---@type (async fun())[]
            local actions = vim.iter(to_update)
                :map(function(name, rock)
                    return nio.create(function()
                        local future = helpers.install({
                            name = name,
                            version = rock.target_version,
                        })
                        local success = pcall(future.wait)
                        if not success then
                            nio.scheduler()
                            report_error(("Failed to update %s."):format(rock.name))
                        end
                    end)
                end)
                :totable()
            nio.gather(actions)
            for _, handler in pairs(external_update_handlers) do
                local function report_progress(message)
                    progress_handle:report({
                        message = message,
                    })
                end
                handler(report_progress, report_error)
            end

            if vim.tbl_isempty(to_update) and vim.tbl_isempty(external_update_handlers) then
                progress_handle:report({ message = "Nothing to update!", percentage = 100 })
            end
            -- Update the version for all installed rocks in case rocks.toml is out of date [#380]
            for _, installed_rock in pairs(state.installed_rocks()) do
                ---@type rock_name
                local rock_name = installed_rock.name
                local rocks_key, user_rock = helpers.get_rock_and_key(user_rocks, installed_rock.name)
                if user_rock and user_rock.version then
                    -- Rock is configured as a table -> Update version.
                    user_rocks[rocks_key][rock_name].version = installed_rock.version
                elseif user_rock then -- Only insert the version if there's an entry in rocks.toml
                    user_rocks[rocks_key][rock_name] = installed_rock.version
                end
            end
            fs.write_file_await(config.config_path, "w", tostring(user_rocks))
            nio.scheduler()
            if not vim.tbl_isempty(error_handles) then
                local message = "Update completed with errors! Run ':Rocks log' for details."
                log.error(message)
                progress_handle:report({
                    title = "Error",
                    message = message,
                    percentage = 100,
                })
                progress_handle:cancel()
                for _, error_handle in pairs(error_handles) do
                    error_handle:cancel()
                end
            else
                progress_handle:finish()
            end
            cache.populate_removable_rock_cache()

            -- Re-generate help tags
            if config.generate_help_pages then
                vim.cmd.helptags("ALL")
            end
            if on_complete then
                on_complete()
            end
        end)
    end)
end

return update
