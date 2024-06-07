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
---@field luarocks_binary? string Luarocks binary path. Defaults to `{rocks_path}/bin/luarocks`.
---@field lazy? boolean Whether to query luarocks.org lazily. Defaults to `false`. Setting this to `true` may improve startup time, but features like auto-completion will lag initially.
---@field dynamic_rtp? boolean Whether to automatically add freshly installed plugins to the 'runtimepath'. Defaults to `true` for the best default experience.
---@field generate_help_pages? boolean Whether to re-generate plugins help pages after installation/upgrade.
---@field reinstall_dev_rocks_on_update? boolean Whether to reinstall 'dev' rocks on update (Default: `true`, as rocks.nvim cannot determine if 'dev' rocks are up to date).
---@field enable_luarocks_loader? boolean Whether to use the luarocks loader to support multiple dependencies (Default: `true`)
---@field luarocks_config? string Path to the luarocks config. If not set, rocks.nvim will create one in `rocks_path`. Warning: You should include the settings in the default luarocks-config.lua before overriding this.

---@type RocksOpts | fun():RocksOpts
vim.g.rocks_nvim = vim.g.rocks_nvim

return config
