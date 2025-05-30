---@mod rocks.operations.pin
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
-- This module handles the pin operation.
--
---@brief ]]

local pin = {}

local helpers = require("rocks.operations.helpers")
local nio = require("nio")

---@param rock_name rock_name
pin.pin = function(rock_name)
    nio.run(function()
        helpers.semaphore.with(function()
            local user_config = helpers.parse_rocks_toml()
            local rocks_key, user_rock = helpers.get_rock_and_key(user_config, rock_name)
            if not rocks_key then
                vim.schedule(function()
                    vim.notify(rock_name .. " not found in rocks.toml", vim.log.levels.ERROR)
                end)
                return
            end
            if type(user_rock) == "string" then
                local version = user_config[rocks_key][rock_name]
                user_config[rocks_key][rock_name] = {}
                user_config[rocks_key][rock_name].version = version
            end
            user_config[rocks_key][rock_name].pin = true
            local version = user_config[rocks_key][rock_name].version
            user_config:_write_await()
            vim.schedule(function()
                vim.notify(("%s pinned to version %s"):format(rock_name, version), vim.log.levels.INFO)
            end)
        end)
    end)
end

return pin
