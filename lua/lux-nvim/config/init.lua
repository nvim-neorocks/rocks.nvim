---@mod lux-config lux.nvim configuration
---
---@brief [[
---
--- You can set lux.nvim configuration options via `vim.g.lux_nvim`.
---
--->
--- ---@type luxOpts
--- vim.g.lux_nvim
---<
---
---@brief ]]

local config = {}

---@tag vim.g.lux_nvim
---@tag g:lux_nvim
---@class LuxConfig
---
-- TODO(vhyrro): Generate these automatically from lux-lua
---@field server string
---@field extra_servers string[]
---@field only_sources string
---@field namespace string
---@field lua_dir string
---@field user_tree fun(lua_version: string)
---@field no_force boolean
---@field verbose boolean
---@field timeout number
---@field cache_dir string
---@field data_dir string
---@field entrypoint_layout table
---@field variables table<string, string>
---@field make_cmd string
---@field cmake_cmd string
---@field enabled_dev_servers string[]
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
--- Whether to update remote plugins after installation/upgrade. (Default: `true`).
---@field update_remote_plugins? boolean
---
--- Whether to auto-sync if plugins cannot be found on startup. (Default: `false`).
--- If unset, lux.nvim will prompt to sync.
---@field auto_sync? boolean

---@type LuxConfig | fun():LuxConfig
vim.g.lux_nvim = vim.g.lux_nvim

return config
