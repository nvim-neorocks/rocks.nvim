-- Initialize rocks
require("rocks").init()

-- Set up the Rocks user command
require("rocks.commands").create_commands()

---@type RocksConfig
local config = require("rocks.config.internal")

if not config.lazy then
    require("nio").run(require("rocks.cache").populate_cached_rocks)
end
