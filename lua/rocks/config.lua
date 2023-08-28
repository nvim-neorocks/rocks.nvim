--- config.lua --- rocks.nvim config module
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
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

return config

--- config.lua ends here
