---@toc rocks.contents

---@mod rocks.nvim rocks.nvim
---
---@brief [[
---
---A luarocks plugin manager for Neovim.
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    20 Mar 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

---@mod rocks.lua rocks.nvim Lua API

local rocks = {}

---Search for a rock with `opt = true`, add it to the runtimepath and source any plugin files found.
---@param rock_name string
---@param opts rocks.PackaddOpts
function rocks.packadd(rock_name, opts)
    require("rocks.runtime").packadd(rock_name, opts)
end

---@class rocks.PackaddOpts
---@field bang? boolean If `true`, rocks.nvim will only add the rock to the runtimepath, but not source any plugin or ftdetect scripts. Default: `false`.
---@field packadd_fallback? boolean Fall back to the builtin |packadd|? Default `true`.

return rocks
