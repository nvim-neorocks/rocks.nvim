vim.g.rocks_nvim = {
    rocks_path = vim.fs.joinpath(vim.fn.getcwd(), "rocks"),
    _log_level = vim.log.levels.TRACE,
}

local luarocks_path = {
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "share", "lua", "5.1", "?.lua"),
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
}
package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

local luarocks_cpath = {
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "lib", "lua", "5.1", "?.dll"),
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "lib64", "lua", "5.1", "?.dll"),
}
package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

local log = require("rocks.log")
log.trace("loading nio")
-- local nio require("nio")
log.trace("loading rocks.adapter")
local adapter = require("rocks.adapter")
log.trace("loading rocks config")
local config = require("rocks.config.internal")

-- Set up the Rocks user command
require("rocks.commands").create_commands()
local env_path_seperator = vim.uv.os_uname().sysname:lower():find("windows") and ";" or ":"
log.trace("Appending luarocks binary directory to the system path with separator " .. env_path_seperator)
vim.env.PATH = vim.fs.joinpath(config.rocks_path, "bin") .. env_path_seperator .. vim.env.PATH
--
-- if not config.lazy then
--     log.trace("Populating caches")
--     nio.run(function()
--         local cache = require("rocks.cache")
--         nio.gather({
--             cache.populate_cached_rocks,
--             cache.populate_removable_rock_cache,
--         })
--     end)
-- end
--
adapter.init()

local config_file = require("rocks.fs").read_or_create(config.config_path, require("rocks.constants").DEFAULT_CONFIG)
vim.print(config_file)
require("toml_edit")
-- toml.decode(config_file)
-- local user_rocks = config.get_user_rocks()
-- vim.print(user_rocks)
-- require("rocks.api.hooks").run_preload_hooks(user_rocks)
-- require("rocks.runtime").source_start_plugins(user_rocks)

-- vim.opt.runtimepath:append(
--     vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "lib", "luarocks", "rocks-5.1", "rocks.nvim", "*")
-- )
