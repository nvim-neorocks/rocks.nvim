local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}
local nio = require("nio")
local fs = require("rocks.fs")
local config = require("rocks.config.internal")
vim.env.PLENARY_TEST_TIMEOUT = 60000 * 5
describe("bulk install", function()
    nio.tests.it("synchronises rocks installations", function()
        local to_install = {
            { name = "neorg", version = "7.0.0" },
            { name = "sweetie.nvim", version = "2.4.0" },
            { name = "rustaceanvim", version = "4.0.0" },
            { name = "haskell-tools.nvim", version = "3.0.0" },
            { name = "neotest", version = "5.2.3" },
        }
        local actions = vim.iter(to_install)
            :map(function(entry)
                return nio.create(function()
                    local future = nio.control.future()
                    require("rocks.api").install(entry.name, entry.version, function()
                        future.set(true)
                    end)
                    future.wait()
                end)
            end)
            :totable()
        nio.gather(actions)
        local config_file = fs.read_or_create(config.config_path, "")
        local rocks_toml = tostring(require("toml_edit").parse(config_file))
        assert.is_not_nil(rocks_toml:find([[neorg = "7%.0%.0"]]))
        assert.is_not_nil(rocks_toml:find([["sweetie%.nvim" = "2%.4%.0"]]))
        assert.is_not_nil(rocks_toml:find([[rustaceanvim = "4%.0%.0"]]))
        assert.is_not_nil(rocks_toml:find([["haskell%-tools%.nvim" = "3%.0%.0"]]))
        assert.is_not_nil(rocks_toml:find([[neotest = "5%.2%.3"]]))
    end)
end)
