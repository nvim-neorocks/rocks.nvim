---@mod rocks rocks.runtime
---
---@brief [[
---
---Functions for adding rocks to the runtimepath and sourcing them
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    25 Dec 2023
-- Updated:    25 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

local runtime = {}

local constants = require("rocks.constants")
local log = require("rocks.log")

---@alias rock_pattern "*" | rock_name

---@class rocks.PackaddOpts
---@field bang? boolean

---@param rock_name rock_name
---@param opts? rocks.PackaddOpts
---@return boolean found
function runtime.packadd(rock_name, opts)
    ---@cast rock_name rock_name
    opts = vim.tbl_deep_extend("force", {
        bang = false,
    }, opts or {})
    local ok, err = pcall(vim.cmd.packadd, { rock_name, bang = opts.bang })
    if not ok and err and err:find("Directory not found in 'packpath'") == nil then
        vim.schedule(function()
            vim.notify(err, vim.log.levels.ERROR)
        end)
    elseif not ok then
        return false
    end
    return true
end

---@param rock_spec RockSpec
---@return boolean?
local function is_start_plugin(rock_spec)
    return not rock_spec.opt and rock_spec.version and rock_spec.name ~= constants.ROCKS_NVIM
end

---Source all plugins with `opt ~= true`
---NOTE: We don't want this to be async,
---to ensure Neovim sources `after/plugin` scripts
---after we source start plugins.
---@param user_rocks RockSpec[]
function runtime.source_start_plugins(user_rocks)
    log.trace("Sourcing start plugins")
    local not_found = {}
    for _, rock_spec in pairs(user_rocks) do
        if is_start_plugin(rock_spec) and not runtime.packadd(rock_spec.name) then
            table.insert(not_found, rock_spec.name)
        end
    end
    if #not_found > 0 then
        vim.schedule(function()
            vim.notify(
                ("rocks.nvim: You may need to run 'Rocks sync'.\nThe following plugins were not found:\n%s."):format(
                    vim.inspect(not_found)
                ),
                vim.log.levels.WARN
            )
        end)
    end
end

return runtime
