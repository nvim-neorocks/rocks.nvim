local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
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
local rtp_link_dir = vim.fs.joinpath(config.rocks_path, "rocks_rtp")
local parser_dir = vim.fs.joinpath(rtp_link_dir, "parser")
describe("rocks.adapter", function()
    nio.tests.it("Sets up and removes symlinks when tree-sitter parser is installed/uninstalled", function()
        assert.is_nil(vim.uv.fs_stat(parser_dir))
        -- TODO: Set fixed version when stable parsers have been released
        helpers.install({ name = "tree-sitter-toml", version = "dev" }).wait()
        adapter.init()
        assert.is_not_nil(vim.uv.fs_stat(parser_dir))
        helpers.remove("tree-sitter-toml").wait()
        adapter.init()
        assert.is_nil(vim.uv.fs_stat(parser_dir))
    end)
    nio.tests.it("Can run checkhealth for luarocks plugins", function()
        local mock_health = mock({
            check = function(_) end,
        })
        vim.health.ok = mock_health.ok
        helpers.install({ name = "telescope.nvim", version = "0.1.6" }).wait()
        require("telescope.health").check = mock_health.check
        adapter.init()
        vim.cmd.checkhealth("telescope")
        assert.spy(mock_health.check).called_at_least(1)
    end)
end)
