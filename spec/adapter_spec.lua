local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
}

local nio = require("nio")
vim.env.PLENARY_TEST_TIMEOUT = 60000
local adapter = require("rocks.adapter")
local config = require("rocks.config.internal")
local helpers = require("rocks.operations.helpers")
local mock = require("luassert.mock")

local luarocks_path = {
    vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?.lua"),
    vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
}
package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

adapter.init()
describe("rocks.adapter", function()
    nio.tests.it("Can run checkhealth for luarocks plugins", function()
        local mock_health = mock({
            check = function(_) end,
        })
        vim.health.ok = mock_health.ok
        helpers.install({ name = "telescope.nvim", version = "0.1.6" }).wait()
        assert.is_not_nil(vim.cmd.Telescope)
        nio.scheduler()
        assert.same("function", type(require("telescope.health").check))
        require("telescope.health").check = mock_health.check
        adapter.init()
        nio.sleep(1000)
        nio.scheduler()
        vim.cmd.checkhealth("telescope")
        assert.spy(mock_health.check).called_at_least(1)
    end)
end)
