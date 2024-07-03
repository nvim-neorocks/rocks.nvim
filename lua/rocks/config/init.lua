---@mod rocks-config rocks.nvim configuration
---
---@brief [[
---
--- You can set rocks.nvim configuration options via `vim.g.rocks_nvim`.
---
--->
--- ---@type RocksOpts
--- vim.g.rocks_nvim
---<
---
---@brief ]]

local config = {}

---@tag vim.g.rocks_nvim
---@tag g:rocks_nvim
---@class RocksOpts
---
--- Local path in your file system to install rocks
--- (Default: a `rocks` directory in `vim.fn.stdpath("data")`).
---@field rocks_path? string
---
--- Rocks declaration file path (Default: `rocks.toml`) in `vim.fn.stdpath("config")`.
---@field config_path? string
---
--- Luarocks binary path (Default: `{rocks_path}/bin/luarocks`).
---@field luarocks_binary? string
---
--- Whether to query luarocks.org lazily (Default: `false`).
--- Setting this to `true` may improve startup time,
--- but features like auto-completion will lag initially.
---@field lazy? boolean
---
--- Whether to automatically add freshly installed plugins to the 'runtimepath'.
--- (Default: `true` for the best default experience).
---@field dynamic_rtp? boolean
---
--- Whether to re-generate plugins help pages after installation/upgrade. (Default: `true`).
---@field generate_help_pages? boolean
---
--- Whether to reinstall 'dev' rocks on update
--- (Default: `true`, as rocks.nvim cannot determine if 'dev' rocks are up to date).
---@field reinstall_dev_rocks_on_update? boolean
---
--- Whether to use the luarocks loader to support multiple dependencies (Default: `true`).
---@field enable_luarocks_loader? boolean
---
--- Extra luarocks config options.
--- rocks.nvim will create a default luarocks config in `rocks_path` and merge it with this table (if set).
---@field luarocks_config? table

---@type RocksOpts | fun():RocksOpts
vim.g.rocks_nvim = vim.g.rocks_nvim

return config
