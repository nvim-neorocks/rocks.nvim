-- NOTE: This rockspec is used for running busted tests only,
-- not for publishing to LuaRocks.org

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "rocks.nvim"
version = _MODREV .. _SPECREV

dependencies = {
    "lua >= 5.1",
    "toml-edit >= 0.1.5",
    "toml",
    "fidget.nvim >= 1.1.0",
    "fzy",
    "nvim-nio",
}

test_dependencies = {
    "lua >= 5.1",
    "toml-edit >= 0.1.5",
    "toml",
    "fidget.nvim >= 1.1.0",
    "fzy",
    "nvim-nio",
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
