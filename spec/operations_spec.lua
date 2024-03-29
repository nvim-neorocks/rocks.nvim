describe("operations.helpers", function()
    local helpers = require("rocks.operations.helpers")
    local config = require("rocks.config.internal")
    vim.system({ "mkdir", "-p", config.rocks_path })
    it("install", function()
        helpers.install({ name = "plenary.nvim" }).wait_sync()
        ---@diagnostic disable-next-line: missing-fields
        local result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result > 0, "install failed")
    end)
    it("remove", function()
        helpers.remove("plenary.nvim").wait_sync()
        ---@diagnostic disable-next-line: missing-fields
        local result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result == 0, "remove failed")
    end)
end)
