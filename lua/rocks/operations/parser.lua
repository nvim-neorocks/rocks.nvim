---@mod rocks.operations.parser
---
---@brief [[
---
---Parsing functions for install operations
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- License:    GPLv3
-- Created:    02 Apr 2024
-- Updated:    02 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

-- NOTE(mrcjkb): This shares some logic with the arg parser in rocks-git.nvim,
-- but it isn't exactly the same, and extracting shared logic would require
-- a higher order (generic) function.
-- I'm sticking to the rule of 3 regarding extracting duplicate logic for now.

local parser = {}

---@param str string
---@return boolean?
local function str_to_bool(str)
    local map = { ["true"] = true, ["1"] = true, ["false"] = false, ["0"] = false }
    return map[str]
end

---@class rocks.InstallSpec
---@field opt? boolean If 'true', will not be loaded on startup. Can be loaded manually with `:Rocks[!] packadd`.
---@field pin? boolean If 'true', will not be updated.
---@field version? string version to install.

---@enum rocks.InstallSpecField
local InstallSpecField = {
    version = tostring,
    opt = str_to_bool,
    pin = str_to_bool,
}

---@class rocks.ParseInstallArgsResult
---@field invalid_args string[]
---@field conflicting_args string[]
---@field spec rocks.InstallSpec

---@param args string[]
---@return rocks.ParseInstallArgsResult
function parser.parse_install_args(args)
    ---@type rocks.ParseInstallArgsResult
    local result = vim.iter(args):fold({ invalid_args = {}, conflicting_args = {}, spec = {} }, function(acc, arg)
        ---@cast acc rocks.ParseInstallArgsResult
        local field, value = arg:match("^([^=]+)=(.+)")
        if not field or not value then
            table.insert(acc.invalid_args, arg)
            return acc
        end
        local mapper = InstallSpecField[field]
        if not mapper then
            table.insert(acc.invalid_args, arg)
            return acc
        end
        local mapped_value = mapper(value)
        if mapped_value == nil then
            table.insert(acc.invalid_args, arg)
            return acc
        end
        if acc.spec[field] and acc.spec[field] ~= mapped_value then
            table.insert(acc.conflicting_args, arg)
            table.insert(acc.conflicting_args, field .. "=" .. tostring(acc.spec[field]))
            return acc
        end
        acc.spec[field] = mapped_value
        return acc
    end)
    if not result.spec.version and #result.invalid_args == 1 and result.invalid_args[1]:find("=") == nil then
        -- Single arg without a field prefix = version.
        result.spec.version = result.invalid_args[1]
        result.invalid_args = {}
    end
    return result
end

return parser
