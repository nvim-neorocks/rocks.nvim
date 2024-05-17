---@mod rocks.config.internal rocks.nvim internal configuration
--
-- Copyright (C) 2023 Neorocks Org.
--
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    15 May 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- rocks.nvim configuration options (internal)
--
---@brief ]]

---@type RocksConfig
local config = {}

local constants = require("rocks.constants")
local fs = require("rocks.fs")

---@diagnostic disable-next-line: param-type-mismatch
local default_rocks_path = vim.fs.joinpath(vim.fn.stdpath("data"), "rocks")

---@param rocks_path string
---@return string
local function get_default_luarocks_binary(rocks_path)
    -- NOTE: On Windows, the binary installed with the luarocks rock is luarocks.bat,
    -- but that doesn't seem to work with vim.system.
    local default_luarocks_path = vim.fs.joinpath(rocks_path, "bin", "luarocks")
    return vim.uv.fs_stat(default_luarocks_path) and default_luarocks_path or "luarocks"
end

local default_luarocks_binary = get_default_luarocks_binary(default_rocks_path)

--- rocks.nvim default configuration
---@class RocksConfig
local default_config = {
    ---@type string Local path in your filesystem to install rocks
    rocks_path = default_rocks_path,
    ---@type string Rocks declaration file path
    ---@diagnostic disable-next-line: param-type-mismatch
    config_path = vim.fs.joinpath(vim.fn.stdpath("config"), "rocks.toml"),
    ---@type string Luarocks binary path
    luarocks_binary = get_default_luarocks_binary(default_rocks_path),
    ---@type boolean Whether to query luarocks.org lazily
    lazy = false,
    ---@type boolean Whether to automatically add freshly installed plugins to the 'runtimepath'
    dynamic_rtp = true,
    ---@type boolean Whether to re-generate plugins help pages after installation/upgrade
    generate_help_pages = true,
    ---@type boolean Whether to reinstall 'dev' rocks on update
    reinstall_dev_rocks_on_update = true,
    ---@type boolean Whether to use the luarocks loader to support multiple dependencies
    enable_luarocks_loader = true,

    -- Internal configs
    ---@type string
    default_luarocks_binary = default_luarocks_binary,
    ---@class RocksConfigDebugInfo
    debug_info = {
        ---@type boolean
        was_g_rocks_nvim_sourced = vim.g.rocks_nvim ~= nil,
        ---@type string[]
        unrecognized_configs = {},
    },
    ---@type fun():RocksToml
    get_rocks_toml = function()
        local config_file = fs.read_or_create(config.config_path, constants.DEFAULT_CONFIG)
        local rocks_toml = require("toml_edit").parse_as_tbl(config_file)
        for key, tbl in pairs(rocks_toml) do
            if key == "rocks" or key == "plugins" then
                for name, data in pairs(tbl) do
                    if type(data) == "string" then
                        ---@type RockSpec
                        rocks_toml[key][name] = {
                            name = name,
                            version = data,
                        }
                    else
                        rocks_toml[key][name].name = name
                    end
                end
            end
        end
        return rocks_toml
    end,
    ---@type fun():table<rock_name, RockSpec>
    get_user_rocks = function()
        local rocks_toml = config.get_rocks_toml()
        return vim.tbl_deep_extend("force", vim.empty_dict(), rocks_toml.rocks or {}, rocks_toml.plugins or {})
    end,
    ---@type string
    luarocks_config = nil,
}

---@type RocksOpts
local opts = type(vim.g.rocks_nvim) == "function" and vim.g.rocks_nvim() or vim.g.rocks_nvim or {}

local check = require("rocks.config.check")

config = vim.tbl_deep_extend("force", {
    debug_info = {
        urecognized_configs = check.get_unrecognized_keys(opts, default_config),
    },
}, default_config, opts)
---@cast config RocksConfig

if not opts.luarocks_binary and opts.rocks_path and opts.rocks_path ~= default_rocks_path then
    -- luarocks_binary has not been overridden, but rocks_path has
    ---@diagnostic disable-next-line: inject-field
    config.default_luarocks_binary = get_default_luarocks_binary(opts.rocks_path)
    ---@diagnostic disable-next-line: inject-field
    config.luarocks_binary = config.default_luarocks_binary
end

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

if opts.luarocks_config then
    -- luarocks_config override
    if vim.uv.fs_stat(opts.luarocks_config) then
        ---@diagnostic disable-next-line: inject-field
        config.luarocks_config = ("%s"):format(opts.luarocks_config)
    else
        vim.notify("rocks.nvim: luarocks_config does not exist!", vim.log.levels.ERROR)
        opts.luarocks_config = nil
    end
end
if not opts.luarocks_config then
    local luarocks_config_path = vim.fs.joinpath(config.rocks_path, "luarocks-config.lua")
    fs.write_file(
        luarocks_config_path,
        "w+",
        ([==[
lua_version = "5.1"
rocks_trees = {
    {
      name = "rocks.nvim",
      root = "%s",
    },
}
]==]):format(config.rocks_path)
    )

    ---@diagnostic disable-next-line: inject-field
    config.luarocks_config = ("%s"):format(luarocks_config_path)
end

return config

--- config.lua ends here
