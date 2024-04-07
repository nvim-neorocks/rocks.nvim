local tempdir = vim.fs.dirname(vim.fn.tempname())
vim.fn.mkdir(tempdir, "p")
vim.g.rocks_nvim = {
    rocks_path = tempdir,
}
local nio = require("nio.tests")
vim.env.PLENARY_TEST_TIMEOUT = 10000
describe("operations.helpers", function()
    local helpers = require("rocks.operations.helpers")
    local config = require("rocks.config.internal")
    vim.system({ "mkdir", "-p", config.rocks_path }):wait()
    nio.it("install/remove", function()
        helpers.install({ name = "plenary.nvim" }).wait()
        ---@diagnostic disable-next-line: missing-fields
        local result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result > 0, "install failed")
        helpers.remove("plenary.nvim").wait()
        ---@diagnostic disable-next-line: missing-fields
        result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result == 0, "remove failed")
    end)
end)
