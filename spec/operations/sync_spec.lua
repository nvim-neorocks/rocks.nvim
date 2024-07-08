local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}
local nio = require("nio")
local operations = require("rocks.operations")
local helpers = require("rocks.operations.helpers")
local state = require("rocks.state")
local config = require("rocks.config.internal")
vim.env.PLENARY_TEST_TIMEOUT = 60000 * 5
describe("operations", function()
    vim.system({ "mkdir", "-p", config.rocks_path }):wait()
    nio.tests.it("sync", function()
        -- Test sync without any rocks
        local config_content = [[
[rocks]

[plugins]
]]
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        local future = nio.control.future()
        operations.sync(config.get_user_rocks(), function()
            future.set(true)
        end)
        future.wait()
        config_content = [[
[rocks]
nlua = "0.1.0"

[plugins]
"haskell-tools.nvim" = "3.0.0"
"sweetie.nvim" = "1.2.1"
]]
        fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        -- One package with a plenary.nvim dependency to remove
        helpers.install({ name = "telescope.nvim", version = "0.1.6" }).wait()
        -- One to downgrade
        helpers.install({ name = "sweetie.nvim", version = "3.0.0" }).wait()
        -- One to update (removing the dependency on plenary.nvim)
        helpers.install({ name = "haskell-tools.nvim", version = "2.4.0" }).wait()
        -- and nlua to install
        local installed_rocks = state.installed_rocks()
        assert.is_not_nil(installed_rocks["telescope.nvim"])
        assert.is_not_nil(installed_rocks["plenary.nvim"])
        assert.is_nil(installed_rocks.nlua)
        assert.same({
            name = "sweetie.nvim",
            version = "3.0.0",
        }, installed_rocks["sweetie.nvim"])
        assert.same({
            name = "haskell-tools.nvim",
            version = "2.4.0",
        }, installed_rocks["haskell-tools.nvim"])
        future = nio.control.future()
        operations.sync(config.get_user_rocks(), function()
            future.set(true)
        end)
        future.wait()
        installed_rocks = state.installed_rocks()
        assert.is_nil(installed_rocks["telescope.nvim"])
        assert.is_nil(installed_rocks["plenary.nvim"])
        assert.same({
            name = "sweetie.nvim",
            version = "1.2.1",
        }, installed_rocks["sweetie.nvim"])
        assert.same({
            name = "haskell-tools.nvim",
            version = "3.0.0",
        }, installed_rocks["haskell-tools.nvim"])
        assert.same({
            name = "nlua",
            version = "0.1.0",
        }, installed_rocks.nlua)
    end)
end)
