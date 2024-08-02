vim.env.PLENARY_TEST_TIMEOUT = 60000

local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}

describe("config", function()
    local config = require("rocks.config.internal")
    local constants = require("rocks.constants")
    it("default servers", function()
        assert.same(constants.DEFAULT_ROCKS_SERVERS, config.get_servers())
    end)
    it("default dev servers", function()
        assert.same(constants.DEFAULT_DEV_SERVERS, config.get_dev_servers())
    end)
    it("override servers", function()
        local config_content = [[
[rocks]

[plugins]

[luarocks]
servers = []
]]
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        assert.same({}, config.get_servers())
    end)
    it("override dev_servers", function()
        local config_content = [[
[rocks]

[plugins]

[luarocks]
dev_servers = []
]]
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        assert.same({}, config.get_dev_servers())
    end)
end)
