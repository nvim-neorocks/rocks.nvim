---@mod rocks.luarocks
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    19 Jul 2023
-- Updated:    27 Aug 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- Functions for interacting with the luarocks CLI
--
---@brief ]]

local luarocks = {}

local constants = require("rocks.constants")
local config = require("rocks.config.internal")
local log = require("rocks.log")
local nio = require("nio")

---@class LuarocksCliOpts: vim.SystemOpts
---@field servers? server_url[] | only_server_url
---@field synchronized? boolean Whether to wait for and acquire a lock (recommended for file system IO, default: `true`)

local lock = nio.control.future()
lock.set(true) -- initialise as unlocked

--- --only-server if `servers` is a `string`, otherwise --server for each element
---@param servers server_url[]|only_server_url|nil
---@return string[]
local function mk_server_args(servers)
    if type(servers) == "string" then
        ---@cast servers string
        return { ("--only-server='%s'"):format(servers) }
    end
    return vim.iter(servers or {})
        :map(function(server)
            ---@cast server string
            return ("--server='%s'"):format(server)
        end)
        :totable()
end

---@param args string[] luarocks CLI arguments
---@param on_exit (function|nil) Called asynchronously when the luarocks command exits.
---   asynchronously. Receives SystemCompleted object, see return of SystemObj:wait().
---@param opts? LuarocksCliOpts
---@return vim.SystemObj
---@see vim.system
luarocks.cli = function(args, on_exit, opts)
    opts = opts or {}
    opts.synchronized = opts.synchronized ~= nil and opts.synchronized or false
    local on_exit_wrapped = vim.schedule_wrap(function(sc)
        if opts.synchronized then
            pcall(lock.set, true)
        end
        ---@cast sc vim.SystemCompleted
        if sc.code ~= 0 then
            log.error("luarocks CLI FAILED")
            log.error(sc.stderr)
        end
        if on_exit then
            on_exit(sc)
        end
    end)
    if opts.synchronized then
        lock.wait()
        lock = nio.control.future()
    end
    opts.env = vim.tbl_deep_extend("force", opts.env or {}, {
        LUAROCKS_CONFIG = "",
        TREE_SITTER_LANGUAGE_VERSION = tostring(vim.treesitter.language_version),
    })
    local luarocks_cmd = {
        config.luarocks_binary,
        "--lua-version=" .. constants.LUA_VERSION,
        "--tree=" .. config.rocks_path,
    }
    luarocks_cmd = vim.list_extend(luarocks_cmd, mk_server_args(opts.servers))
    luarocks_cmd = vim.list_extend(luarocks_cmd, args)
    log.info(luarocks_cmd)
    return vim.system(luarocks_cmd, opts, on_exit_wrapped)
end

---@class LuarocksSearchOpts
---@field dev? boolean Include dev manifest? Default: false
---@field servers? server_url[]|only_server_url Optional servers. Defaults to constants.ROCKS_SERVERS

---Search luarocks.org for all packages.
---@type async fun(callback: fun(rocks_table: { [string]: Rock } ), opts?: LuarocksSearchOpts)
luarocks.search_all = nio.create(function(callback, opts)
    ---@cast opts LuarocksSearchOpts | nil
    local rocks_table = vim.empty_dict()
    ---@cast rocks_table { [string]: Rock }
    local future = nio.control.future()
    local cmd = { "search", "--porcelain", "--all" }
    if opts and opts.dev then
        table.insert(cmd, "--dev")
    end
    luarocks.cli(cmd, function(obj)
        ---@cast obj vim.SystemCompleted
        future.set(obj)
    end, { text = true, synchronized = false, servers = opts and opts.servers or constants.ALL_SERVERS })
    ---@type vim.SystemCompleted
    local obj = future.wait()
    local result = obj.stdout
    if obj.code ~= 0 or not result then
        callback(vim.empty_dict())
        return
    end
    for name, version in result:gmatch("(%S+)%s+(%S+)%s+[^\n]+") do
        if name ~= "lua" then
            local rock_list = rocks_table[name] or vim.empty_dict()
            ---@cast rock_list Rock[]
            -- Exclude -<specrev> from version
            table.insert(rock_list, { name = name, version = version:match("([^-]+)") })
            rocks_table[name] = rock_list
        end
    end
    callback(rocks_table)
end, 1)

return luarocks

-- end of luarocks.lua
