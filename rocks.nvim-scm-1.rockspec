-- NOTE: This rockspec is used for running busted tests only,
-- not for publishing to LuaRocks.org

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "rocks.nvim"
version = _MODREV .. _SPECREV

dependencies = {
    "lua >= 5.1",
    "luarocks >= 3.11.1, < 4.0.0",
    "toml-edit >= 0.5.0",
    "fidget.nvim >= 1.1.0",
    "fzy",
    "nvim-nio",
    "rtp.nvim",
}

test_dependencies = {
    "lua >= 5.1",
    "luarocks >= 3.11.1, < 4.0.0",
    "toml-edit >= 0.5.0",
    "fidget.nvim >= 1.1.0",
    "fzy",
    "nvim-nio",
    "rtp.nvim",
    "nlua",
}

source = {
    url = "git://github.com/nvim-neorocks/" .. package,
}

build = {
    type = "builtin",
    copy_directories = {
        'doc',
        "plugin",
    },
}
