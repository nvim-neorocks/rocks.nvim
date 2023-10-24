---@mod rocks.config rocks.nvim configuration
---
---@brief [[
--
-- rocks.nvim configuration options
--
---@brief ]]

local config = {}

---@class RocksOpts
---@field rocks_path? string Local path in your filesystem to install rocks. Defaults to a `rocks` directory in `vim.fn.stdpath("data")`.
---@field config_path? string Rocks declaration file path. Defaults to `rocks.toml` in `vim.fn.stdpath("config")`.

---@type RocksOpts | fun():RocksOpts
vim.g.rocks_nvim = vim.g.rocks_nvim

return config
