---@mod rocks-api-hooks rocks.nvim API hooks
---
---@brief [[
---
---Hooks that rocks.nvim modules can inject behaviour into.
---Intended for use by modules that extend this plugin.
---
--- Preload hooks                                                *rocks.hooks.preload*
---
--- By providing a module with the pattern, `rocks-<extension>.rocks.hooks.preload`,
--- rocks.nvim modules can execute code before rocks.nvim loads any plugins
--- (but after they have been added to the runtimepath).
--- The module should return a table of type |rocks.hooks.Preload|.
---
--- To be able to use this feature, a rocks.nvim extension *must* be named with a 'rocks-'
--- prefix.
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    19 Mar 2024
-- Updated:    19 Jun 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

---@class rocks.hooks.RockSpecModifier
---@field hook rock_spec_modifier
---@field type 'RockSpecModifier'

---@class rocks.hooks.Action
---@field hook fun(user_rocks: table<rock_name, RockSpec>)
---@field type 'Action'

---@alias rocks.hooks.Preload rocks.hooks.RockSpecModifier | rocks.hooks.Action

---@alias rock_spec_modifier fun(rock: RockSpec):RockSpec

local hooks = {}

local log = require("rocks.log")
local config = require("rocks.config.internal")

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

---@package
---@param user_rocks table<rock_name, RockSpec>
---@return table<rock_name, RockSpec> user_rocks
function hooks.run_preload_hooks(user_rocks)
    log.trace("Running preload hooks")
    ---@type fun(user_rocks: RockSpec[])[]
    local actions = {}
    for _, rock_spec in pairs(user_rocks) do
        local rock_extension_module_name = not rock_spec.opt and get_rocks_extension_module_name(rock_spec)
        local loader = rock_extension_module_name and search_for_preload_hook(rock_extension_module_name)
        if loader then
            -- NOTE We want this to panic if it fails, as it could otherwise
            -- lead to harder to debug error messages.
            local preload_hook = loader()
            if type(preload_hook) == "table" and preload_hook.type then
                ---@cast preload_hook rocks.hooks.Preload
                if preload_hook.type == "Action" then
                    table.insert(actions, preload_hook.hook)
                elseif preload_hook.type == "RockSpecModifier" then
                    config.register_rock_spec_modifier(preload_hook.hook)
                end
            end
        end
    end
    user_rocks = config.apply_rock_spec_modifiers(user_rocks)
    for _, action in pairs(actions) do
        action(user_rocks)
    end
    return user_rocks
end

return hooks
