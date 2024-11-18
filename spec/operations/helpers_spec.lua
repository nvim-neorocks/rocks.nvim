local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    experimental_features = { "ext_module_dependency_stubs" },
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
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
            dependencies = { "pathlib.nvim == 2.2.3" },
        })
        installed_rocks = state.installed_rocks()
        assert.same({
            name = "stub.nvim",
            version = "1.0.0",
        }, installed_rocks["stub.nvim"])
        assert.same({
            name = "pathlib.nvim",
            version = "2.2.3",
        }, installed_rocks["pathlib.nvim"])
        helpers.manage_rock_stub({
            rock = { name = "stub.nvim", version = "1.0.0" },
            action = "prune",
        })
        installed_rocks = state.installed_rocks()
        assert.is_nil(installed_rocks["stub.nvim"])
        assert.is_nil(installed_rocks["pathlib.nvim"])
    end)
    it("Parse rocks toml", function()
        local config_content = [[
import = [
  "local-rocks.toml",
]
[rocks]
myrock = "1.0.0"

[plugins]
myplugin = "1.0.0"

[luarocks]
servers = ["server1", "server2"]
]]
        local config_content2 = [[
import = [
  "rocks.toml", # SHOULD IGNORE CIRCULAR IMPORT
]
[plugins."myplugin"]
version = "2.0.0"
pin = true
]]

        local _, _ = os.remove(vim.fs.joinpath(tempdir, "local-rocks.toml"))
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "local-rocks.toml"), "w"),
            "Could not open local rocks.toml for writing"
        )
        fh:write(config_content2)
        fh:close()

        local rocks_toml = helpers.parse_rocks_toml()
        assert.is_not_nil(rocks_toml.rocks)
        assert.same("1.0.0", rocks_toml.rocks.myrock)
        assert.is_not_nil(rocks_toml.plugins)
        assert.same("2.0.0", rocks_toml.plugins.myplugin.version) -- local overrides base
        assert.same(true, rocks_toml.plugins.myplugin.pin)
        assert.is_not_nil(rocks_toml.luarocks)
        assert.same("server1", rocks_toml.luarocks.servers[1])
        assert.same("server2", rocks_toml.luarocks.servers[2])
        assert.same(nil, rocks_toml.luarocks.servers[3])
        assert.is_not_nil(rocks_toml.import)
    end)
    it("Parse rocks toml passing base config path", function()
        local config_content = [[
[rocks]
myrock = "1.0.0"
]]

        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()

        local rocks_toml = helpers.parse_rocks_toml(config.config_path)
        assert.is_not_nil(rocks_toml.rocks)
        assert.same("1.0.0", rocks_toml.rocks.myrock)
    end)
    it("Parse rocks toml passing new import path", function()
        local config_content = [[
[rocks]
myrock = "1.0.0"
]]

        local _, _ = os.remove(vim.fs.joinpath(tempdir, "local-rocks.toml"))
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()

        local rocks_toml = helpers.parse_rocks_toml("local-rocks.toml")
        assert.same(nil, rocks_toml.rocks)
    end)
    it("Parse rocks toml passing existing import path", function()
        local config_content = [[
[rocks]
myrock = "1.0.0"
]]
        local config_content2 = [[
[plugins."myplugin"]
version = "2.0.0"
pin = true
]]

        local _, _ = os.remove(vim.fs.joinpath(tempdir, "local-rocks.toml"))
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        fh = assert(
            io.open(vim.fs.joinpath(tempdir, "local-rocks.toml"), "w"),
            "Could not open local rocks.toml for writing"
        )
        fh:write(config_content2)
        fh:close()

        local rocks_toml = helpers.parse_rocks_toml("local-rocks.toml")
        assert.same(nil, rocks_toml.rocks)
        assert.same("2.0.0", rocks_toml.plugins.myplugin.version)
        assert.same(true, rocks_toml.plugins.myplugin.pin)
    end)
end)

describe("operations.helpers.multi_mut_rocks_toml_wrapper", function()
    local multi_mut_rocks_toml_wrapper = require("rocks.operations.helpers.multi_mut_rocks_toml_wrapper")
    it("Create new with no config", function()
        assert.error(function()
            local _ = multi_mut_rocks_toml_wrapper.new({})
        end)
    end)
    it("Item retrival", function()
        local table1 = {
            a = "table1_a",
            b = "table1_b",
            c = {
                a = "table1_c_a",
                b = "table1_c_b",
                c = "table1_c_c",
            },
        }
        local table2 = {
            b = "table2_b",
            c = {
                d = "table2_c_d",
            },
            d = "table2_d",
        }
        local m = multi_mut_rocks_toml_wrapper.new({
            {
                config = table1,
                path = "path1",
            },
            {
                config = table2,
                path = "path2",
            },
        })
        ---@diagnostic disable-next-line: undefined-field
        assert.same("table1_a", m.a) -- Only in table1
        ---@diagnostic disable-next-line: undefined-field
        assert.same("table1_b", m.b) -- Prefer table1 since it is first
        ---@diagnostic disable-next-line: undefined-field
        local c = m.c -- Nested table, prefer table1 values since first
        assert.same("table1_c_a", c.a)
        assert.same("table1_c_b", c.b)
        assert.same("table1_c_c", c.c)
        ---@diagnostic disable-next-line: undefined-field
        assert.same("table2_c_d", m.c.d) -- Nested table value, only in table2
        ---@diagnostic disable-next-line: undefined-field
        assert.same("table2_d", m.d) -- Only in table2
    end)
    it("Item modification", function()
        local table1 = {
            a = "table1_a",
            b = "table1_b",
            c = {
                a = "table1_c_a",
                b = "table1_c_b",
                c = "table1_c_c",
            },
        }
        local table2 = {
            b = "table2_b",
            c = {
                d = "table2_c_d",
            },
            d = "table2_d",
        }
        local m = multi_mut_rocks_toml_wrapper.new({
            {
                config = table1,
                path = "path1",
            },
            {
                config = table2,
                path = "path2",
            },
        })

        -- Table1 modified
        ---@diagnostic disable-next-line: inject-field
        m.a = "foo"
        assert.same("foo", table1.a)
        assert.same(nil, table2.a)

        -- Table1 modified since first
        ---@diagnostic disable-next-line: inject-field
        m.b = "foo"
        assert.same("foo", table1.b)
        assert.same("table2_b", table2.b)
    end)
    it("Item insertion", function()
        local table1 = {
            a = "table1_a",
            b = "table1_b",
            c = {
                a = "table1_c_a",
                b = "table1_c_b",
                c = "table1_c_c",
            },
        }
        local table2 = {
            b = "table2_b",
            c = {
                d = "table2_c_d",
            },
            d = "table2_d",
        }
        local m = multi_mut_rocks_toml_wrapper.new({
            {
                config = table1,
                path = "path1",
            },
            {
                config = table2,
                path = "path2",
            },
        })

        -- Table1 modified since first
        ---@diagnostic disable-next-line: inject-field
        m.z = "new_z_value"
        assert.same("new_z_value", table2.z)
        assert.same(nil, table1.z)
    end)
end)
