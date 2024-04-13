---@mod rocks.api.hooks rocks.nvim API hooks
---
---@brief [[
---
---Hooks that rocks.nvim modules can inject behaviour into.
---Intended for use by modules that extend this plugin.
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    19 Mar 2024
-- Updated:    11 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

local hooks = {}

local log = require("rocks.log")

---@param rock RockSpec
---@return string | nil
local function get_rocks_extension_module_name(rock)
    return rock.name:match("(rocks%-[^%.%-]+)")
end

---Find a preload hook by rock name
---@param rock_name rock_name
---@return function | nil
local function search_for_preload_hook(rock_name)
    local mod_name = rock_name .. ".rocks.hooks.preload"
    if package.loaded[mod_name] then
        return
    end
    for _, searcher in ipairs(package.loaders) do
        local loader = searcher(mod_name)
        if type(loader) == "function" then
            package.preload[mod_name] = loader
            return loader
        end
    end
end

---@brief [[
---
--- |preload|
--- By providing a module with the pattern, `rocks-<extension>.rocks.hooks.preload`,
--- rocks.nvim modules can execute code before rocks.nvim loads any plugins
--- (but after they have been added to the runtimepath).
---
--- To be able to use this feature, a rocks.nvim extension *must* be named with a 'rocks-'
--- prefix.
---
---@brief ]]

---@package
---@param user_rocks RockSpec[]
function hooks.run_preload_hooks(user_rocks)
    log.trace("Running preload hooks")
    for _, rock_spec in pairs(user_rocks) do
        local rock_extension_module_name = not rock_spec.opt and get_rocks_extension_module_name(rock_spec)
        local hook = rock_extension_module_name and search_for_preload_hook(rock_extension_module_name)
        if hook then
            -- NOTE We want this to panic if it fails, as it could otherwise
            -- lead to harder to debug error messages.
            hook()
        end
    end
end

return hooks
