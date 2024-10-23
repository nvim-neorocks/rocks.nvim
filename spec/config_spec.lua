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
    it("get config basic", function()
        local config_content = [[
[rocks]
myrock = "1.0.0"

[plugins]
myplugin = "1.0.0"

[plugins."myotherplugin"]
version = "2.0.0"
pin = true

[luarocks]
servers = []
]]
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        local rocks_toml = config.get_rocks_toml()
        assert.same({
            rocks = {
                myrock = {
                    name = "myrock",
                    version = "1.0.0",
                },
            },
            plugins = {
                myplugin = {
                    name = "myplugin",
                    version = "1.0.0",
                },
                myotherplugin = {
                    name = "myotherplugin",
                    version = "2.0.0",
                    pin = true,
                },
            },
            luarocks = {
                servers = {}
            }
        }, rocks_toml)
    end)
    it("get config with imports", function()
        local config_content = [[
import = [
  "local-rocks.toml",
]
[rocks]
myrock = "1.0.0"

[plugins]
myplugin = "1.0.0"

[luarocks]
servers = []
]]
        local config_content2 = [[
import = [
  "rocks.toml", # SHOULD IGNORE CIRCULAR IMPORT
]
[plugins."myotherplugin"]
version = "2.0.0"
pin = true
]]

        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        fh = assert(io.open(vim.fs.joinpath(tempdir, "local-rocks.toml"), "w"),
            "Could not open local rocks.toml for writing")
        fh:write(config_content2)
        fh:close()
        local rocks_toml = config.get_rocks_toml()
        assert.same({
            rocks = {
                myrock = {
                    name = "myrock",
                    version = "1.0.0",
                },
            },
            plugins = {
                myplugin = {
                    name = "myplugin",
                    version = "1.0.0",
                },
                myotherplugin = {
                    name = "myotherplugin",
                    version = "2.0.0",
                    pin = true,
                },
            },
            luarocks = {
                servers = {}
            }
        }, rocks_toml)
    end)
end)
