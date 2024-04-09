local loader = {}

local log = require("rocks.log")
local config = require("rocks.config.internal")

local function get_luarocks_lua_dir_from_luarocks()
    local sc = vim.system({ config.luarocks_binary, "--lua-version=5.1", "which", "luarocks.loader" }):wait()
    local result = sc.stdout and sc.stdout:match(vim.fs.joinpath("(%S+)", "5.1", "luarocks", "loader.lua"))
    return result
end

---@return boolean
function loader.enable()
    log.trace("Enabling luarocks loader")
    local default_luarocks_binary = vim.fs.joinpath(config.rocks_path, "bin", "luarocks")
    local luarocks_lua_dir = config.luarocks_binary == default_luarocks_binary
            and vim.fs.joinpath(default_luarocks_binary, "share", "lua")
        or get_luarocks_lua_dir_from_luarocks()
    if luarocks_lua_dir then
        package.path = package.path
            .. ";"
            .. table.concat({
                vim.fs.joinpath(luarocks_lua_dir, "5.1", "?.lua"),
                vim.fs.joinpath(luarocks_lua_dir, "5.1", "init.lua"),
            }, ";")
        vim.env.LUAROCKS_CONFIG = config.luarocks_config
        local ok, err = pcall(require, "luarocks.loader")
        if ok then
            return true
        end
        log.error(err or "Unknown error initializing luarocks loader")
        vim.notify("Failed to initialize luarocks loader: " .. err, vim.log.levels.WARN, {
            title = "rocks.nvim",
        })
    end
    return false
end

return loader
