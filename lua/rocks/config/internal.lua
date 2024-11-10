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

local default_rocks_path = vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "rocks")

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

local notified_recursive_imports = {}

--- rocks.nvim default configuration
---@class RocksConfig
local default_config = {
    ---@type string Local path in your filesystem to install rocks
    rocks_path = default_rocks_path,
    ---@type string Rocks declaration file path
    config_path = vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "rocks.toml"),
    ---@type string Luarocks binary path
    luarocks_binary = get_default_luarocks_binary(default_rocks_path),
    ---@type boolean Whether to query luarocks.org lazily
    lazy = false,
    ---@type boolean Whether to automatically add freshly installed plugins to the 'runtimepath'
    dynamic_rtp = true,
    ---@type boolean Whether to re-generate plugins help pages after installation/upgrade
    generate_help_pages = true,
    ---@type boolean Whether to update remote plugins after installation/upgrade
    update_remote_plugins = true,
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
    ---@type fun(parse_func: (fun(file_str: string, file_path: string): table), process_func: fun(config: table, file_path: string) | nil)
    read_rocks_toml = function(parse_func, process_result)
        local visited = {}

        ---@param file_path string
        ---@param default string
        local function parse(file_path, default)
            -- Don't allow recursive includes
            if visited[file_path] then
                if not notified_recursive_imports[file_path] then
                    vim.defer_fn(function()
                        vim.notify("Recursive import detected: " .. file_path, vim.log.levels.WARN)
                    end, 1000)
                    notified_recursive_imports[file_path] = true
                end
                return nil
            end
            visited[file_path] = true

            -- Read config
            local file_str = fs.read_or_create(file_path, default)
            -- Parse
            local rocks_toml = parse_func(file_str, file_path)
            -- Follow import paths (giving preference to imported config)
            if rocks_toml.import then
                -- NOTE: using a while loop as the imports may be a metatable
                local i = 0
                local import_path
                while true do
                    i = i + 1
                    import_path = rocks_toml.import[i]
                    if import_path == nil then
                        break
                    end
                    parse(fs.get_absolute_path(vim.fs.dirname(config.config_path), import_path), "")
                end
            end
            if process_result then
                process_result(rocks_toml, file_path)
            end
        end
        parse(config.config_path, constants.DEFAULT_CONFIG)
    end,
    ---@type fun():RocksToml
    get_rocks_toml = function()
        local rocks_toml_merged = {}
        config.read_rocks_toml(function(file_str)
            -- Parse
            return require("toml_edit").parse_as_tbl(file_str)
        end, function(rocks_toml, _)
            -- Setup rockspec for rocks/plugins
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
            -- Merge into configuration, in the order of preference returned by the read function
            rocks_toml_merged = vim.tbl_deep_extend("keep", rocks_toml_merged, rocks_toml)
        end)
        rocks_toml_merged.import = nil -- Remove import field since we merged

        return rocks_toml_merged
    end,
    ---@return server_url[]
    get_servers = function()
        local luarocks_opts = config.get_rocks_toml().luarocks
        -- WARNING: Return a copy of the constant table so it can't be modified by the caller
        return luarocks_opts and type(luarocks_opts.servers) == "table" and luarocks_opts.servers
            or vim.deepcopy(constants.DEFAULT_ROCKS_SERVERS)
    end,
    ---@return server_url[]
    get_dev_servers = function()
        local luarocks_opts = config.get_rocks_toml().luarocks
        -- WARNING: Return a copy of the constant table so it can't be modified by the caller
        return luarocks_opts and type(luarocks_opts.dev_servers) == "table" and luarocks_opts.dev_servers
            or vim.deepcopy(constants.DEFAULT_DEV_SERVERS)
    end,
    ---@return server_url[]
    get_all_servers = function()
        return vim.list_extend(config.get_servers(), config.get_dev_servers())
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

    ---@type rocks.ExperimentalFeatureFlags
    experimental_features = {},
}

---@class rocks.ExperimentalFeatureFlags
---@field [rocks.ExperimentalFeature] boolean

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
    local sysname_map = {
        Linux = "linux",
        Darwin = "macosx",
        Windows_NT = "win32",
    }
    local machine_map = {
        arm64 = "aarch64",
        aarch64 = "aarch64",
        x86_64 = "x86_64",
    }
    local uname = vim.uv.os_uname()
    local sysname = sysname_map[uname.sysname]
    local machine = machine_map[uname.machine] or uname.machine
    local arch = sysname and machine and ("%s-%s"):format(sysname, machine)
    local default_luarocks_config = {
        lua_version = "5.1",
        rocks_trees = {
            {
                name = "rocks.nvim",
                root = config.rocks_path,
            },
        },
        arch = arch,
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
    local luarocks_config = opts.luarocks_config
    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast luarocks_config string
    vim.deprecate(
        "g:rocks_nvim.luarocks_config (string)",
        "g:rocks_nvim.luarocks_config (table)",
        "3.0.0",
        "rocks.nvim"
    )
    -- luarocks_config override
    if vim.uv.fs_stat(luarocks_config) then
        local luarocks_config_path = ("%s"):format(luarocks_config)
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

if type(opts.experimental_features) == "table" then
    config.experimental_features = vim.iter(opts.experimental_features):fold(
        {},
        ---@param acc table<rocks.ExperimentalFeature, boolean>
        ---@param feature rocks.ExperimentalFeature
        function(acc, feature)
            acc[feature] = true
            return acc
        end
    )
end

return config

--- config.lua ends here
