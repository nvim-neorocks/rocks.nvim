local loader = {}

local log = require("rocks.log")
local config = require("rocks.config.internal")

---@return string | nil
local function get_luarocks_lua_dir_from_luarocks()
    ---@type boolean, vim.SystemObj
    local ok, so = pcall(vim.system, { config.luarocks_binary, "--lua-version=5.1", "which", "luarocks.loader" }, nil)
    if not ok then
        log.error(("Could not invoke luarocks at %s"):format(config.luarocks_binary))
        return
    end
    ---@type vim.SystemCompleted
    local sc = so:wait()
    local result = sc.stdout and sc.stdout:match(vim.fs.joinpath("(%S+)", "5.1", "luarocks", "loader.lua"))
    return result
end

---@return boolean success
function loader.enable()
    local luarocks_config_path = config.luarocks_config_path()
    log.trace("Enabling luarocks loader")
    local luarocks_lua_dir = config.luarocks_binary == config.default_luarocks_binary
            and vim.fs.joinpath(config.rocks_path, "share", "lua")
        or get_luarocks_lua_dir_from_luarocks()
    if luarocks_lua_dir then
        package.path = package.path
            .. ";"
            .. table.concat({
                vim.fs.joinpath(luarocks_lua_dir, "5.1", "?.lua"),
                vim.fs.joinpath(luarocks_lua_dir, "5.1", "init.lua"),
            }, ";")
        vim.env.LUAROCKS_CONFIG = luarocks_config_path
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
