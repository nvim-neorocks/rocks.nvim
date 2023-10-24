---@mod rocks
--
-- Copyright (C) 2023 NTBBloodbath
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>
--
---@brief [[
--
-- rocks.nvim main module
--
---@brief ]]

local rocks = {}

local setup = require("rocks.setup")
local config = require("rocks.config")

---@param opts RocksOptions
function rocks.setup(opts)
    assert(vim.version() >= vim.version.parse("0.10.0-dev"), "rocks.nvim requires Neovim 0.10.0 or later!")

    config = vim.tbl_deep_extend("force", config, opts or {})

    setup.init()
    setup.bootstrap_dependencies()
end

return rocks

--- init.lua ends here
