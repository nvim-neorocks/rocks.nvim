vim.env.PLENARY_TEST_TIMEOUT = 60000
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
}
local loader = require("rocks.loader")
local nio = require("nio")

describe("rocks.loader", function()
    nio.tests.it("Can enable luarocks.loader", function()
        assert.True(loader.enable())
    end)
end)
