---@mod rocks.config.check rocks.nvim config validation
--
-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    24 Oct 2023
-- Updated:    24 Oct 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>
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
    })
    if not ok then
        return false, err
    end
    return true
end

return check
