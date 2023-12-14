---@mod rocks.config.internal rocks.nvim internal configuration
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>
--
---@brief [[
--
-- rocks.nvim configuration options (internal)
--
---@brief ]]

---@class (exact) RocksConfig
---@field rocks_path string Local path in your filesystem to install rocks
---@field config_path string Rocks declaration file path
---@field luarocks_binary string Luarocks binary path
---@field lazy boolean Whether to query luarocks.org lazily.
---@field dynamic_rtp boolean Whether to automatically add freshly installed plugins to the 'runtimepath'.
---@field debug_info RocksConfigDebugInfo

---@class (exact) RocksConfigDebugInfo
---@field was_g_rocks_nvim_sourced boolean
---@field unrecognized_configs string[]

--- rocks.nvim default configuration
---@type RocksConfig
local default_config = {
    ---@diagnostic disable-next-line: param-type-mismatch
    rocks_path = vim.fs.joinpath(vim.fn.stdpath("data"), "rocks"),
    ---@diagnostic disable-next-line: param-type-mismatch
    config_path = vim.fs.joinpath(vim.fn.stdpath("config"), "rocks.toml"),
    luarocks_binary = "luarocks",
    lazy = false,
    dynamic_rtp = true,
    debug_info = {
        was_g_rocks_nvim_sourced = vim.g.rocks_nvim ~= nil,
        unrecognized_configs = {},
    },
}

---@type RocksOpts
local opts = type(vim.g.rocks_nvim) == "function" and vim.g.rocks_nvim() or vim.g.rocks_nvim or {}

local check = require("rocks.config.check")

---@type RocksConfig
local config = vim.tbl_deep_extend("force", {
    debug_info = {
        urecognized_configs = check.get_unrecognized_keys(opts, default_config),
    },
}, default_config, opts)

local ok, err = check.validate(config)
if not ok then
    vim.notify("Rocks: " .. err, vim.log.levels.ERROR)
end

if #config.debug_info.unrecognized_configs > 0 then
    vim.notify(
        "unrecognized configs found in vim.g.rocks_nvim: " .. vim.inspect(config.debug_info.unrecognized_configs),
        vim.log.levels.WARN
    )
end

return config

--- config.lua ends here
