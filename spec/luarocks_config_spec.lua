local nio = require("nio")

vim.env.PLENARY_TEST_TIMEOUT = 60000

describe("luarocks config", function()
    nio.tests.it("extra luarocks_config", function()
        local tempdir = vim.fn.tempname()

        local external_deps_dirs = {
            "/some/path",
        }

        vim.g.rocks_nvim = {
            luarocks_binary = "luarocks",
            rocks_path = tempdir,
            luarocks_config = {
                external_deps_dirs = external_deps_dirs,
            },
        }

        local config = require("rocks.config.internal")
        nio.sleep(2000)
        assert.is_not_nil(vim.uv.fs_stat(config.luarocks_config))
        local luarocks_config = {}
        loadfile(config.luarocks_config, "t", luarocks_config)()
        assert.same({
            lua_version = "5.1",
            external_deps_dirs = external_deps_dirs,
            rocks_trees = {
                { name = "rocks.nvim", root = tempdir },
            },
        }, luarocks_config)
    end)
end)
