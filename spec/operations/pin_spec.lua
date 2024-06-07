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
describe("install/pin/update", function()
    local operations = require("rocks.operations")
    local state = require("rocks.state")
    nio.tests.it("update skips pinned install", function()
        local future = nio.control.future()
        operations.add({ "neorg", "7.0.0", "pin=true" }, function()
            future.set(true)
        end)
        future.wait()
        local installed_rocks = state.installed_rocks()
        assert.same({
            name = "neorg",
            version = "7.0.0",
        }, installed_rocks["neorg"])
        future = nio.control.future()
        operations.update(function()
            future.set(true)
        end)
        future.wait()
        installed_rocks = state.installed_rocks()
        assert.same({
            name = "neorg",
            version = "7.0.0",
        }, installed_rocks["neorg"])
    end)
end)
