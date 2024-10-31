---@mod rocks.operations.prune
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
-- This module handles the prune operation.
--
---@brief ]]

local prune = {}

local constants = require("rocks.constants")
local log = require("rocks.log")
local config = require("rocks.config.internal")
local cache = require("rocks.cache")
local helpers = require("rocks.operations.helpers")
local handlers = require("rocks.operations.handlers")
local nio = require("nio")
local progress = require("fidget.progress")
local adapter = require("rocks.adapter")

---Uninstall a rock, pruning it from rocks.toml.
---@param rock_name string
prune.prune = function(rock_name)
    local progress_handle = progress.handle.create({
        title = "Pruning",
        lsp_client = { name = constants.ROCKS_NVIM },
    })
    nio.run(function()
        helpers.semaphore.with(function()
            local user_config = helpers.parse_rocks_toml()
            if user_config.plugins then
                user_config.plugins[rock_name] = nil
            end
            if user_config.rocks then
                user_config.rocks[rock_name] = nil
            end
            local success = true -- initialised for handlers
            if helpers.is_installed(rock_name) then
                success = helpers.remove_recursive(rock_name, nil, progress_handle)
            end
            -- NOTE: We always delegate to handlers, even if the rock is installed,
            -- so we can allow them to manage luarocks packages.
            local function report_progress(message)
                progress_handle:report({ message = message })
            end
            local function report_error(message)
                progress_handle:report({ message = message, title = "Error" })
                success = false
            end
            user_config:_write_await()
            local user_rocks = config.get_user_rocks()
            handlers.prune_user_rocks(user_rocks, report_progress, report_error)
            adapter.synchronise_site_symlinks()
            cache.populate_all_rocks_state_caches()
            vim.schedule(function()
                if success then
                    progress_handle:finish()
                else
                    local message = "Prune completed with errors! Run ':Rocks log' for details."
                    log.error(message)
                    progress_handle:report({
                        title = "Error",
                        message = message,
                    })
                    progress_handle:cancel()
                end
            end)
        end)
    end)
end

return prune
