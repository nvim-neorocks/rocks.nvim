---@mod lux.operations.search lux.nvim package searching
---
---@brief [[
---
---Search for packages available on luarocks.org
---
---@brief ]]

local nio = require("nio")

local search = {}

---@class LuarocksSearchOpts
---@field dev? boolean Include dev manifest? Default: false
---@field servers? server_url[]|only_server_url Optional servers. Defaults to constants.ROCKS_SERVERS

---Search luarocks.org for all packages.
---@type async fun(callback: fun(rocks_table: { [string]: Rock } ), opts?: LuarocksSearchOpts)
search.search_all = nio.create(function(callback, opts)
    require("lux").operations.search()
end)

return search
