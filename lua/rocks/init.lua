-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    05 Jul 2023
-- Updated:    24 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks.nvim
-- Maintainers: NTBBloodbath <bloodbathalchemist@protonmail.com>, Vhyrro <vhyrro@gmail.com>, mrcjkb <marc@jakobi.dev>

local rocks = {}

---@deprecated
function rocks.packadd(rock_name, opts)
    vim.deprecate("rocks.packadd", "Neovim's built-in 'packadd'", "3.0.0", "rocks.nvim")
    require("rocks.runtime").packadd(rock_name, opts)
end

return rocks
