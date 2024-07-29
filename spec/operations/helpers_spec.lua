local tempdir = vim.fn.tempname()
vim.fn.mkdir(tempdir, "p")
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    experimental_features = { "ext_module_dependency_stubs" },
}
local nio = require("nio")
vim.env.PLENARY_TEST_TIMEOUT = 60000
describe("operations.helpers", function()
    local helpers = require("rocks.operations.helpers")
    local config = require("rocks.config.internal")
    local state = require("rocks.state")
    vim.system({ "mkdir", "-p", config.rocks_path }):wait()
    nio.tests.it("install/remove", function()
        helpers.install({ name = "plenary.nvim" }).wait()
        ---@diagnostic disable-next-line: missing-fields
        local result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result > 0, "install failed")
        helpers.remove("plenary.nvim").wait()
        ---@diagnostic disable-next-line: missing-fields
        result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result == 0, "remove failed")
        local GIT2_DIR = os.getenv("GIT2_DIR")
        if type(GIT2_DIR) == "string" then
            helpers
                .install({
                    name = "fugit2.nvim",
                    version = "0.2.0",
                    install_args = { "GIT2_DIR=" .. GIT2_DIR },
                })
                .wait()
            local installed_rocks = require("rocks.state").installed_rocks()
            assert.same({
                name = "fugit2.nvim",
                version = "0.2.0",
            }, installed_rocks["fugit2.nvim"])
        else
            print("GIT2_DIR not set. Skipping install_args test case")
        end
    end)
    it("Detect breaking changes", function()
        local result = helpers.get_breaking_changes({
            foo = { name = "foo", version = "7.0.0", target_version = "8.0.0" },
            bar = { name = "bar", version = "7.0.0", target_version = "7.1.0" },
            baz = { name = "baz", version = "7.0.0", target_version = "7.1.1" },
        })
        assert.is_not_nil(result.foo)
        assert.is_nil(result.bar)
        assert.is_nil(result.baz)
        assert.same("foo 7.0.0 -> 8.0.0", tostring(result.foo))
    end)
    nio.tests.it("Install rock stub", function()
        local installed_rocks = state.installed_rocks()
        assert.is_nil(installed_rocks["stub.nvim"])
        helpers.manage_rock_stub({
            rock = { name = "stub.nvim", version = "1.0.0" },
            action = "install",
        })
        installed_rocks = state.installed_rocks()
        assert.same({
            name = "stub.nvim",
            version = "1.0.0",
        }, installed_rocks["stub.nvim"])
        helpers.manage_rock_stub({
            rock = { name = "stub.nvim", version = "1.0.0" },
            action = "prune",
        })
        installed_rocks = state.installed_rocks()
        assert.is_nil(installed_rocks["stub.nvim"])
    end)
end)
