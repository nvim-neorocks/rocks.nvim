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

---@class rocks.LuarocksCliOpts: vim.SystemOpts
---@field servers? server_url[] | only_server_url
---@field synchronized? boolean Whether to wait for and acquire a lock (recommended for file system IO, default: `true`)

-- NOTE: We cannot share the semaphore with operations.helpers, or it would deadlock
local semaphore = nio.control.semaphore(1)

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
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the luarocks command exits.
---   asynchronously. Receives SystemCompleted object, see return of SystemObj:wait().
---@param opts? rocks.LuarocksCliOpts
---@see vim.system
luarocks.cli = nio.create(function(args, on_exit, opts)
    opts = opts or {}
    -- This should prevent issues like #312 and #554
    opts.cwd = opts.cwd or config.rocks_path
    ---@cast opts rocks.LuarocksCliOpts
    opts.synchronized = opts.synchronized ~= nil and opts.synchronized or true
    local on_exit_wrapped = vim.schedule_wrap(function(sc)
        if opts.synchronized then
            semaphore.release()
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
        semaphore.acquire()
    end
    opts.env = vim.tbl_deep_extend("force", opts.env or {}, {
        LUAROCKS_CONFIG = config.luarocks_config_path(),
        TREE_SITTER_LANGUAGE_VERSION = tostring(vim.treesitter.language_version),
        LUA_PATH = ('"%s"'):format(package.path),
        LUA_CPATH = ('"%s"'):format(package.cpath),
    })
    local luarocks_cmd = {
        config.luarocks_binary,
        "--force-lock",
        "--lua-version=" .. constants.LUA_VERSION,
        "--tree=" .. config.rocks_path,
    }
    luarocks_cmd = vim.list_extend(luarocks_cmd, mk_server_args(opts.servers))
    luarocks_cmd = vim.list_extend(luarocks_cmd, args)
    log.info(luarocks_cmd)
    -- Prevent luarocks from exiting uncleanly
    -- NOTE: detach spawns new terminal windows on Windows.
    opts.detach = vim.uv.os_uname().sysname:lower():find("windows") == nil
    local ok, err = pcall(vim.system, luarocks_cmd, opts, on_exit_wrapped)
    if not ok then
        ---@type vim.SystemCompleted
        local sc = {
            code = 1,
            signal = 0,
            stderr = ("Failed to invoke luarocks at %s: %s"):format(config.luarocks_binary, err),
        }
        on_exit_wrapped(sc)
    end
end, 3)

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
    end, {
        text = true,
        servers = opts and opts.servers or config.get_all_servers(),
    })
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
end, 2)

return luarocks

-- end of luarocks.lua
