local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}
local nio = require("nio")
vim.env.PLENARY_TEST_TIMEOUT = 60000 * 5
describe("install/update", function()
    local operations = require("rocks.operations")
    local state = require("rocks.state")
    nio.tests.it("install and update rocks", function()
        local future = nio.control.future()
        operations.add({ "Neorg", "7.0.0" }, function() -- ensure lower case
            future.set(true)
        end)
        future.wait()
        local installed_rocks = state.installed_rocks()
        assert.same({
            name = "neorg",
            version = "7.0.0",
        }, installed_rocks.neorg)
        local user_rocks = require("rocks.config.internal").get_user_rocks()
        assert.same({
            name = "neorg",
            version = "7.0.0",
        }, user_rocks.neorg)
        future = nio.control.future()
        operations.update(function()
            future.set(true)
        end)
        future.wait()
        installed_rocks = state.installed_rocks()
        local updated_version = vim.version.parse(installed_rocks.neorg.version)
        assert.True(updated_version > vim.version.parse("7.0.0"))
    end)
end)
