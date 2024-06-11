---@mod rocks.config.check rocks.nvim config validation
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    24 Oct 2023
-- Updated:    24 Oct 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- rocks.nvim config validation (internal)
--
---@brief ]]

local check = {}

---@param tbl table The table to validate
---@see vim.validate
---@return boolean is_valid
---@return string|nil error_message
local function validate(tbl)
    local ok, err = pcall(vim.validate, tbl)
    return ok or false, "Rocks: Invalid config" .. (err and ": " .. err or "")
end

---Validates the config.
---@param cfg RocksConfig
---@return boolean is_valid
---@return string|nil error_message
function check.validate(cfg)
    local ok, err = validate({
        rocks_path = { cfg.rocks_path, "string" },
        config_path = { cfg.config_path, "string" },
        luarocks_binary = { cfg.luarocks_binary, "string" },
        lazy = { cfg.lazy, "boolean" },
        dynamic_rtp = { cfg.dynamic_rtp, "boolean" },
        generate_help_pages = { cfg.generate_help_pages, "boolean" },
    })
    if not ok then
        return false, err
    end
    if vim.fn.executable(cfg.luarocks_binary) ~= 1 then
        return false, ("Cannot execute %s"):format(cfg.luarocks_binary)
    end
    return true
end

---Recursively check a table for unrecognized keys,
---using a default table as a reference
---@param tbl table
---@param default_tbl table
---@return string[]
function check.get_unrecognized_keys(tbl, default_tbl)
    local unrecognized_keys = {}
    for k, _ in pairs(tbl) do
        unrecognized_keys[k] = true
    end
    for k, _ in pairs(default_tbl) do
        unrecognized_keys[k] = false
    end
    local ret = {}
    for k, _ in pairs(unrecognized_keys) do
        if unrecognized_keys[k] then
            ret[k] = k
        end
        if type(default_tbl[k]) == "table" and tbl[k] then
            for _, subk in pairs(check.get_unrecognized_keys(tbl[k], default_tbl[k])) do
                local key = k .. "." .. subk
                ret[key] = key
            end
        end
    end
    return vim.tbl_keys(ret)
end

return check
