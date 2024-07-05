---@mod rocks.config.internal rocks.nvim internal configuration
--
-- Copyright (C) 2023 Neorocks Org.
--
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    19 Jun 2024
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

---@type rock_spec_modifier[]
local _rock_spec_modifiers = {}

local constants = require("rocks.constants")
local fs = require("rocks.fs")

---@diagnostic disable-next-line: param-type-mismatch
local default_rocks_path = vim.fs.joinpath(vim.fn.stdpath("data"), "rocks")

---@param rocks_path string
---@return string
local function get_default_luarocks_binary(rocks_path)
    -- NOTE: On Windows, the binary installed with the luarocks rock is luarocks.bat,
    -- but that doesn't seem to work with vim.system.
    local luarocks_glob =
        vim.fs.joinpath(rocks_path, "lib", "luarocks", "rocks-5.1", "luarocks", "*", "bin", "luarocks")
    local default_luarocks_path = vim.fn.glob(luarocks_glob)
    return vim.fn.executable(default_luarocks_path) == 1 and default_luarocks_path or "luarocks"
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
    ---@param user_rocks table<rock_name, RockSpec>
    ---@return table<rock_name, RockSpec>
    apply_rock_spec_modifiers = function(user_rocks)
        if vim.tbl_isempty(_rock_spec_modifiers) then
            return user_rocks
        end
        return vim.iter(user_rocks):fold({}, function(acc, name, rock)
            for _, modifier in pairs(_rock_spec_modifiers) do
                acc[name] = modifier(acc[name] or rock)
            end
            return acc
        end)
    end,

    ---@param modifier rock_spec_modifier
    register_rock_spec_modifier = function(modifier)
        table.insert(_rock_spec_modifiers, modifier)
    end,

    ---@type fun():table<rock_name, RockSpec>
    get_user_rocks = function()
        local rocks_toml = config.get_rocks_toml()
        local user_rocks =
            vim.tbl_deep_extend("force", vim.empty_dict(), rocks_toml.rocks or {}, rocks_toml.plugins or {})
        return config.apply_rock_spec_modifiers(user_rocks)
    end,
    ---@type fun():string
    luarocks_config_path = nil,
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

---@return string
local function mk_luarocks_config()
    local default_luarocks_config = {
        lua_version = "5.1",
        rocks_trees = {
            {
                name = "rocks.nvim",
                root = config.rocks_path,
            },
        },
    }
    local luarocks_config = vim.tbl_deep_extend("force", default_luarocks_config, opts.luarocks_config or {})

    local config_str = vim.iter(luarocks_config):fold("", function(acc, k, v)
        return ([[
%s
%s = %s
]]):format(acc, k, vim.inspect(v))
    end)
    require("rocks.log").debug("luarocks config:\n" .. config_str)
    return config_str
end

if type(opts.luarocks_config) == "string" then
    vim.deprecate(
        "g:rocks_nvim.luarocks_config (string)",
        "g:rocks_nvim.luarocks_config (table)",
        "3.0.0",
        "rocks.nvim"
    )
    -- luarocks_config override
    if vim.uv.fs_stat(opts.luarocks_config) then
        local luarocks_config_path = ("%s"):format(opts.luarocks_config)
        ---@diagnostic disable-next-line: inject-field
        config.luarocks_config_path = function()
            return luarocks_config_path
        end
    else
        vim.notify("rocks.nvim: luarocks_config does not exist!", vim.log.levels.ERROR)
        opts.luarocks_config = nil
    end
end
if not opts.luarocks_config or type(opts.luarocks_config) == "table" then
    local luarocks_config_path
    ---@diagnostic disable-next-line: inject-field
    config.luarocks_config_path = function()
        if luarocks_config_path then
            return ("%s"):format(luarocks_config_path)
        end
        luarocks_config_path = vim.fs.joinpath(config.rocks_path, "luarocks-config.lua")
        require("rocks.log").debug("luarocks config path: " .. luarocks_config_path)
        -- NOTE: We don't use fs/libuv here, because we need the file to be written
        -- before it is used
        local fh = io.open(luarocks_config_path, "w+")
        if fh then
            local config_str = mk_luarocks_config()
            fh:write(config_str)
            fh:close()
        else
            require("rocks.log").error(("Could not open %s for writing."):format(luarocks_config_path))
            luarocks_config_path = ""
        end
        ---@diagnostic disable-next-line: inject-field
        return ("%s"):format(luarocks_config_path)
    end
end

return config

--- config.lua ends here
