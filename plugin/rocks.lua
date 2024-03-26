if vim.g.rocks_nvim_loaded then
    return
end

local nio = require("nio")
local adapter = require("rocks.adapter")
local config = require("rocks.config.internal")

local function get_luarocks_loader_path_from_luarocks()
    local sc = vim.system({ config.luarocks_binary, "which", "luarocks.loader" }):wait()
    return sc.stdout and sc.stdout:match("(%S+)loader.lua")
end

-- Initialize the luarocks loader
if config.enable_luarocks_loader then
    local default_luarocks_binary = vim.fs.joinpath(config.rocks_path, "bin", "luarocks")
    local luarocks_loader_path = config.luarocks_binary == default_luarocks_binary
            and vim.fs.joinpath(default_luarocks_binary, "share", "lua", "5.1", "luarocks", "?.lua")
        or get_luarocks_loader_path_from_luarocks()
    if luarocks_loader_path then
        package.path = package.path .. ";" .. luarocks_loader_path .. "?.lua"
        vim.env.LUAROCKS_CONFIG = config.luarocks_config
        local ok, err = pcall(require, "luarocks.loader")
        -- TODO: log errors
        if not ok then
            vim.notify("Failed to initialize luarocks loader: " .. err, vim.log.levels.ERROR, {
                title = "rocks.nvim",
            })
        end
    end
end

-- Set up the Rocks user command
require("rocks.commands").create_commands()

local env_path_seperator = vim.uv.os_uname().sysname:lower():find("windows") and ";" or ":"

-- Append the binary directory to the system path.
vim.env.PATH = vim.fs.joinpath(config.rocks_path, "bin") .. env_path_seperator .. vim.env.PATH

if not config.lazy then
    nio.run(function()
        local cache = require("rocks.cache")
        nio.gather({
            cache.populate_cached_rocks,
            cache.populate_removable_rock_cache,
        })
    end)
end

adapter.init()

--- We don't want to run this async, to ensure proper initialisation order
local user_rocks = config.get_user_rocks()
require("rocks.api.hooks").run_preload_hooks(user_rocks)
require("rocks.runtime").source_start_plugins(user_rocks)

vim.g.rocks_nvim_loaded = true
