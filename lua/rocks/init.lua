---@toc rocks.contents

---@mod rocks rocks.nvim
---
---@brief [[
---
---A luarocks plugin manager for Neovim.
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainer: NTBBloodbath <bloodbathalchemist@protonmail.com>

local rocks = {}

---@package
function rocks.init()
    ---@type RocksConfig
    local config = require("rocks.config.internal")
    local luarocks_path = {
        vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?.lua"),
        vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
    }
    package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

    local luarocks_cpath = {
        vim.fs.joinpath(config.rocks_path, "lib", "lua", "5.1", "?.so"),
        vim.fs.joinpath(config.rocks_path, "lib64", "lua", "5.1", "?.so"),
    }
    package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

    vim.opt.runtimepath:append(vim.fs.joinpath(config.rocks_path, "lib", "luarocks", "rocks-5.1", "*", "*"))
end

return rocks
