describe("operations", function()
    local operations = require("rocks.operations")
    local config = require("rocks.config")
    vim.system({ "mkdir", "-p", config.rocks_path })
    it("install", function()
        operations.install("plenary.nvim").wait_sync()
        local result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result > 0, "install failed")
    end)
    it("remove", function()
        operations.remove("plenary.nvim").wait_sync()
        local result = vim.fs.find("plenary", { path = config.rocks_path, type = "directory" })
        assert(#result == 0, "remove failed")
    end)
end)
