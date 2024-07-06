---@mod rocks.operations
--
-- Copyright (C) 2023 Neorocks Org.
--
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    06 Jul 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>
--
---@brief [[
--
-- This module handles all the operations that has something to do with
-- luarocks. Installing, uninstalling, updating, etc.
--
---@brief ]]

local operations = {
    register_handler = require("rocks.operations.handlers").register_handler,
    update = require("rocks.operations.update").update,
    sync = require("rocks.operations.sync").sync,
    add = require("rocks.operations.add").add,
    prune = require("rocks.operations.prune").prune,
    pin = require("rocks.operations.pin").pin,
    unpin = require("rocks.operations.unpin").unpin,
}

return operations
