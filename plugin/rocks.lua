if vim.g.rocks_nvim_loaded then
    return
end

-- Set up the Rocks user command
require("rocks.commands").create_commands()

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

--- We don't want to run this async, to ensure plugins are sourced before `after/plugin`
require("rocks.runtime").source_start_plugins()

vim.g.rocks_nvim_loaded = true
