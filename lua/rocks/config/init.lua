---@mod rocks.config rocks.nvim configuration
---
---@brief [[
---
--- rocks.nvim configuration options
---
--->
--- ---@type RocksOpts
--- vim.g.rocks_nvim
---<
---
---@brief ]]

local config = {}

---@class RocksOpts
---@field rocks_path? string Local path in your filesystem to install rocks. Defaults to a `rocks` directory in `vim.fn.stdpath("data")`.
---@field config_path? string Rocks declaration file path. Defaults to `rocks.toml` in `vim.fn.stdpath("config")`.
---@field luarocks_binary? string Luarocks binary path. Defaults to `luarocks`.
---@field lazy? boolean Whether to query luarocks.org lazily. Defaults to `false`. Setting this to `true` may improve startup time, but features like auto-completion will lag initially.
---@field dynamic_rtp? boolean Whether to automatically add freshly installed plugins to the 'runtimepath'. Defaults to `true` for the best default experience.
---@field generate_help_pages? boolean Whether to re-generate plugins help pages after installation/upgrade.

---@type RocksOpts | fun():RocksOpts
vim.g.rocks_nvim = vim.g.rocks_nvim

return config
