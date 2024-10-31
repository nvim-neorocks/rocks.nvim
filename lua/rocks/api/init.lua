---@mod rocks-api Lua API for rocks.nvim extensions
---
---@brief [[
---
---The Lua API for rocks.nvim.
---Intended for use by modules that extend this plugin.
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    07 Dec 2023
-- Updated:    25 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

---@alias rock_name string

---@class RockSpec: TomlRockSpec
---@field name string The name of the rock

---@class Rock
---@field name rock_name
---@field version string

local api = {}

local cache = require("rocks.cache")
local commands = require("rocks.commands")
local config = require("rocks.config.internal")
local fzy = require("rocks.fzy")
local luarocks = require("rocks.luarocks")
local nio = require("nio")
local state = require("rocks.state")
local operations = require("rocks.operations")

---Tries to get the cached rocks.
---Returns an empty list if the cache has not been populated
---or no connection to luarocks.org can be established.
---Will spawn an async task to attempt to populate the cache
---if it is not ready.
---@return table<rock_name, Rock[]> rocks
function api.try_get_cached_rocks()
    return cache.try_get_rocks()
end

---@class OutdatedRock: Rock
---@field public target_version string

---Tries to get the cached outdated rocks.
---Returns an empty list if the cache has not been populated
---or no connection to luarocks.org can be established.
---Will spawn an async task to attempt to populate the cache
---if it is not ready.
---@return table<rock_name, OutdatedRock> rocks
function api.try_get_cached_outdated_rocks()
    return cache.try_get_outdated_rocks()
end

---Queries luarocks.org for rocks and passes the rocks
---to a callback. Invokes the callback with an empty table
---if no rocks are found or no connection to luarocks.org can be established.
---@param callback fun(rocks: table<rock_name, Rock[]>)
---@async
function api.query_luarocks_rocks(callback)
    nio.run(function()
        luarocks.search_all(function(rocks)
            callback(rocks)
        end, { dev = true })
    end)
end

---@class FuzzyFilterOpts
---@field sort? boolean Whether to sort the results (default: `true`).

---@generic T
---@param rock_tbl table<rock_name, T>
---@param query string
---@param opts? FuzzyFilterOpts
---@return table<rock_name, T>
function api.fuzzy_filter_rock_tbl(rock_tbl, query, opts)
    vim.validate({ query = { query, "string" } })
    if opts then
        vim.validate({ sort = { opts.sort, "boolean", true } })
    end
    local matching_names = fzy.fuzzy_filter(query, vim.tbl_keys(rock_tbl), opts)
    local result = vim.empty_dict()
    ---@cast result table<rock_name, Rock[]>
    for _, match in pairs(matching_names) do
        result[match] = rock_tbl[match]
    end
    return result
end

---Query for installed rocks.
---Passes the installed rocks (table indexed by name) to a callback when done.
---@param callback fun(rocks: table<rock_name, Rock>)
---@async
function api.query_installed_rocks(callback)
    nio.run(state.installed_rocks, function(success, rocks)
        if success then
            callback(rocks)
        end
    end)
end

---Gets the rocks.toml file path.
---Note that the file may not have been created yet.
---@return string rocks_toml_file_path
function api.get_rocks_toml_path()
    return config.config_path
end

---@class RocksToml
---@field rocks? table<rock_name, RockSpec> The `[rocks]` entries
---@field plugins? table<rock_name, RockSpec> The `[plugins]` entries
---@field servers? string[]
---@field dev_servers? string[]
---@field import? string[]
---@field [string] unknown Fields that can be added by external modules

---Returns a table with the parsed rocks.toml file.
---If the file doesn't exist a file with the default configuration will be created.
---@return RocksToml
function api.get_rocks_toml()
    return config.get_rocks_toml()
end

---Returns a table with the rock specifications parsed from the rocks.toml file.
---If the file doesn't exist a file with the default configuration will be created.
---@return table<rock_name, RockSpec>
function api.get_user_rocks()
    return config.get_user_rocks()
end

---@class RocksCmd
---@field impl fun(args:string[], opts: vim.api.keyset.user_command) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

---Register a `:Rocks` subcommand.
---@param name string The name of the subcommand to register
---@param cmd RocksCmd
function api.register_rocks_subcommand(name, cmd)
    commands.register_subcommand(name, cmd)
end

---@alias rock_config_table table<rock_name, TomlRockSpec|rock_version>

---@alias rock_version string

---A mutable Lua representation of rocks.toml. May be extended by external modules.
---@class MutRocksTomlRef
---@field rocks? rock_config_table
---@field plugins? rock_config_table
---@field [string] unknown

---@class rock_handler.on_success.Opts
---@field action 'install' | 'prune'
---
---The rock stub to install or prune.
---@field rock Rock
---
---The dependency constraints (e.g. { 'foo >= 1.0.0', }).
---@field dependencies? string[]

---@alias rock_handler_callback fun(on_progress: fun(message: string), on_error: fun(message: string), on_success?: fun(opts: rock_handler.on_success.Opts))
---@brief [[
---An async callback that handles an operation on a rock.
---
---  - The `on_success` callback is optional for backward compatibility.
---@brief ]]

---@class RockHandler
---@field get_sync_callback? fun(spec: RockSpec):rock_handler_callback|nil Return a function that installs or updates the rock, or `nil` if the handler cannot or does not need to sync the rock.
---@field get_prune_callback? fun(specs: table<rock_name, RockSpec>):rock_handler_callback|nil Return a function that prunes unused rocks, or `nil` if the handler cannot or does not need to prune any rocks.
---@field get_install_callback? fun(rocks_toml: MutRocksTomlRef, arg_list: string[]):rock_handler_callback|nil Return a function that installs a rock, or `nil` if the handler cannot install this rock. The `rocks_toml` table is mutable, and should be updated with the installed rock by the returned callback.
---@field get_update_callbacks? fun(rocks_toml: MutRocksTomlRef):rock_handler_callback[] Return a list of functions that update user rocks, or an empty list if the handler cannot or does not need to update any rocks. The `rocks_toml` table is mutable, and should be updated by the returned callbacks.

---@param handler RockHandler
function api.register_rock_handler(handler)
    operations.register_handler(handler)
end

---@deprecated Use the rtp.nvim luarock
function api.source_runtime_dir(dir)
    vim.deprecate("rocks.api.source_rtp_dir", "the rtp.nvim luarock", "3.0.0", "rocks.nvim")
    require("rtp_nvim").source_rtp_dir(dir)
end

---@class rocks.InstallOpts
---@field skip_prompts? boolean Whether to skip any "search 'dev' manifest prompts
---@field cmd? 'install' | 'update' Command used to invoke this function. Default: `'install'`
---@field config_path? string Config file path to use for installing the rock relative to the base config file
---@field callback? fun(rock: Rock) Invoked upon successful completion

---Invoke ':Rocks install'
---@param rock_name rock_name #The rock name
---@param version? string The version of the rock to use
---@param opts? rocks.InstallOpts  Installation options
function api.install(rock_name, version, opts)
    if type(opts) == "function" then
        vim.deprecate(
            "rocks.api.install(rock_name, version, callback)",
            "rocks.api.install(rocks_name, version, { callback = cb })",
            "3.0.0",
            "rocks.nvim"
        )
        opts = { callback = opts }
    end
    operations.add({ rock_name, version }, opts --[[@as rocks.AddOpts]])
end

return api
