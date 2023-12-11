-- Initialize rocks
require("rocks").init()

-- Set up the Rocks user command
require("rocks.commands").create_commands()

---@type RocksConfig
local config = require("rocks.config.internal")

if not config.lazy then
    local nio = require("nio")
    nio.run(function()
        local cache = require("rocks.cache")
        nio.gather({
            cache.populate_cached_rocks,
            cache.populate_removable_rock_cache,
        })
    end)
end
