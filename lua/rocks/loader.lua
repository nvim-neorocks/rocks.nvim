local loader = {}

local log = require("rocks.log")
local config = require("rocks.config.internal")
local nio = require("nio")

---@return string | nil
local function get_luarocks_lua_dir_from_luarocks()
    local future = nio.control.future()
    local ok = pcall(
        vim.system,
        { config.luarocks_binary, "--lua-version=5.1", "which", "luarocks.loader" },
        nil,
        function(sc)
            future.set(sc)
        end
    )
    if not ok then
        log.error(("Could not invoke luarocks at %s"):format(config.luarocks_binary))
        return
    end
    ---@type vim.SystemCompleted
    local sc = future.wait()
    local result = sc.stdout and sc.stdout:match(vim.fs.joinpath("(%S+)", "5.1", "luarocks", "loader.lua"))
    return result
end

---@type async fun():boolean
loader.enable = nio.create(function()
    local luarocks_config_path = config.luarocks_config_path()
    local luarocks_lua_dir = config.luarocks_binary == config.default_luarocks_binary
            and vim.fs.joinpath(config.rocks_path, "share", "lua")
        or get_luarocks_lua_dir_from_luarocks()
    local future = nio.control.future()
    vim.schedule(function()
        log.trace("Enabling luarocks loader")
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
                future.set(true)
                return
            end
            log.error(err or "Unknown error initializing luarocks loader")
            vim.notify("Failed to initialize luarocks loader: " .. err, vim.log.levels.WARN, {
                title = "rocks.nvim",
            })
        end
        future.set(false)
    end)
    return future.wait()
end)

return loader
