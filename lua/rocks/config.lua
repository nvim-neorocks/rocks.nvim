--- config.lua --- rocks.nvim config module
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    05 Jul 2023
-- Homepage:   https://github.com/NTBBloodbath/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>
--
-------------------------------------------------------------------------------------------
--
--- Commentary:
--
-- rocks.nvim configuration options
--
-------------------------------------------------------------------------------------------
--
--- Code:

local global_config = require("rocks.config")
local constants = require("rocks.constants")
local fs = require("rocks.fs")
local state = require("rocks.state")

--- rocks.nvim configuration
---@type table
local config = {
  --- Local path in your filesystem to install rocks
  ---@type string
  rocks_path = vim.fs.joinpath(vim.fn.stdpath("data"), "rocks"),
  --- Rocks declaration file path
  ---@type string
  config_path = vim.fs.joinpath(vim.fn.stdpath("config"), "rocks.toml"),
}

function config.read(location)
    -- Read or create a new config file and decode it
    local user_config = require("toml").decode(fs.read_or_create(global_config.config_path, constants.DEFAULT_CONFIG))

    -- Merge `rocks` and `plugins` fields as they are just an eye-candy separator for clarity purposes
    local rocks = vim.tbl_deep_extend("force", user_config.rocks, user_config.plugins)
    local installed_rocks =  

    --- Operations process ---
    --------------------------
    -- ops structure:
    -- {
    --   install = {
    --     foo = "version"
    --   },
    --   remove = {
    --     "bar",
    --     "fizzbuzz",
    --   }
    -- }
    local ops = {
        install = {},
        remove = {},
    }
    for rock, metadata in pairs(rocks) do
        if not vim.tbl_contains(installed_rock_names, rock) then
            ops.install[rock] = metadata
        end
    end
    for _, installed_rock in ipairs(installed_rock_names) do
        -- FIXME: this seems to be removing rocks that are dependencies of some plugins as they are not listed
        --        explicitly in the `rocks.toml` file. We have to fix this as soon as possible.
        if not vim.tbl_contains(vim.tbl_keys(config_rocks), installed_rock) then
            ops.remove[#ops.remove + 1] = installed_rock
        end
    end
end

return config

--- config.lua ends here
