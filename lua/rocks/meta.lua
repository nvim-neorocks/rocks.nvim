-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    03 Aug 2024
-- Updated:    03 Aug 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

---@mod rocks.user-event rocks.nvim |User| |event|s
---
---@brief [[
---The following |User| |event|s are available:
---
---RocksInstallPost			Invoked after installing or updating a rock
---                         The `data` is of type
---                         |rocks.user-events.data.RocksInstallPost|.
---
---
---To create an autocommand for an event:
--->lua
---        vim.api.nvim_create_autocmd("User", {
---          pattern = "RocksInstallPost",
---          callback = function(ev)
---             ---@type rocks.user-events.data.RocksInstallPost
---             local data = ev.data
---             -- ...
---          end,
---        })
---<

---@class rocks.user-events.data.RocksInstallPost
---@field spec RockSpec
---@field installed Rock

error("can't require a meta module")
local meta = {}
return meta
