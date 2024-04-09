if vim.g.rocks_nvim_loaded then
    return
end

local log = require("rocks.log")
log.trace("loading nio")
local nio = require("nio")
log.trace("loading rocks.adapter")
local adapter = require("rocks.adapter")
log.trace("loading rocks config")
local config = require("rocks.config.internal")

-- Initialize the luarocks loader
if config.enable_luarocks_loader then
    require("rocks.loader").enable()
end

-- Set up the Rocks user command
require("rocks.commands").create_commands()

local env_path_seperator = vim.uv.os_uname().sysname:lower():find("windows") and ";" or ":"

-- Append the binary directory to the system path.
log.trace("Appending luarocks binary directory to the system path")
vim.env.PATH = vim.fs.joinpath(config.rocks_path, "bin") .. env_path_seperator .. vim.env.PATH

if not config.lazy then
    log.trace("Populating caches")
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
