if vim.g.rocks_nvim_loaded then
    return
end

local nio = require("nio")

-- Set up the Rocks user command
require("rocks.commands").create_commands()

local config = require("rocks.config.internal")

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

--- We don't want to run this async, to ensure plugins are sourced before `after/plugin`
require("rocks.runtime").source_start_plugins()

--- Neovim doesn't support `:checkhealth` for luarocks plugins.
--- To work around this, we create a symlink in the `rocks_path` that
--- we add to the runtimepath, so that Neovim can find health files.
nio.run(function()
    local log = require("rocks.log")
    local health_link_dir = vim.fs.joinpath(config.rocks_path, "healthlink")
    local lua_symlink_dir = vim.fs.joinpath(health_link_dir, "lua")
    -- NOTE: nio.uv.fs_stat behaves differently than vim.uv.fs_stat
    if not vim.uv.fs_stat(lua_symlink_dir) then
        log.info("Creating health symlink directory.")
        if vim.fn.mkdir(health_link_dir, "p") ~= 1 then
            log.error("Failed to create health symlink directory.")
        end
        local rocks_lua_dir = vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1")
        nio.uv.fs_symlink(rocks_lua_dir, lua_symlink_dir)
    end
    vim.schedule(function()
        vim.opt.runtimepath:append(health_link_dir)
    end)
end)

vim.g.rocks_nvim_loaded = true
