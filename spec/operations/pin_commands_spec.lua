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
local commands = require("rocks.commands")
commands.create_commands()

local function parse_config()
    local config_file_content = fs.read_or_create(config.config_path, "")
    return require("toml_edit").parse(config_file_content)
end

vim.env.PLENARY_TEST_TIMEOUT = 60000 * 5
describe("Rocks pin/unpin", function()
    nio.tests.it("pin/unpin plugin with only version", function()
        local rocks_toml = parse_config()
        rocks_toml.plugins = {}
        rocks_toml.plugins.foo = "1.0.0"
        local completion = vim.fn.getcompletion("Rocks pin ", "cmdline")
        assert.same({}, completion)
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(tostring(rocks_toml))
        fh:close()
        completion = vim.fn.getcompletion("Rocks pin ", "cmdline")
        assert.same({ "foo" }, completion)
        completion = vim.fn.getcompletion("Rocks unpin ", "cmdline")
        assert.same({}, completion)
        vim.cmd.Rocks({ "pin", "foo" })
        nio.sleep(2000) -- wait for rocks.toml to be written
        rocks_toml = parse_config()
        assert.same(
            [[
[plugins]

[plugins.foo ]
version = "1.0.0"
pin = true
]],
            tostring(rocks_toml)
        )
        completion = vim.fn.getcompletion("Rocks unpin ", "cmdline")
        assert.same({ "foo" }, completion)
        vim.cmd.Rocks({ "unpin", "foo" })
        nio.sleep(2000) -- wait for rocks.toml to be written
        rocks_toml = parse_config()
        assert.same(
            [[
[plugins]
foo = "1.0.0"
]],
            tostring(rocks_toml)
        )
    end)
    nio.tests.it("pin plugin with version and opt", function()
        local rocks_toml = parse_config()
        rocks_toml.plugins = {}
        rocks_toml.plugins.foo = {}
        rocks_toml.plugins.foo.version = "1.0.0"
        rocks_toml.plugins.foo.opt = true
        local completion = vim.fn.getcompletion("Rocks pin ", "cmdline")
        assert.same({ "foo" }, completion)
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(tostring(rocks_toml))
        fh:close()
        vim.cmd.Rocks({ "pin", "foo" })
        nio.sleep(2000) -- wait for rocks.toml to be written
        rocks_toml = parse_config()
        assert.same(
            [[
[plugins]

[plugins.foo]
version = "1.0.0"
opt = true
pin = true
]],
            tostring(rocks_toml)
        )
        vim.cmd.Rocks({ "unpin", "foo" })
        nio.sleep(2000) -- wait for rocks.toml to be written
        rocks_toml = parse_config()
        assert.same(
            [[
[plugins]

[plugins.foo]
version = "1.0.0"
opt = true
]],
            tostring(rocks_toml)
        )
    end)
    nio.tests.it("pin plugin with only version as table", function()
        local rocks_toml = parse_config()
        rocks_toml.plugins = {}
        rocks_toml.plugins.foo = {}
        rocks_toml.plugins.foo.version = "1.0.0"
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(tostring(rocks_toml))
        fh:close()
        vim.cmd.Rocks({ "pin", "foo" })
        nio.sleep(2000) -- wait for rocks.toml to be written
        rocks_toml = parse_config()
        assert.same(
            [[
[plugins]

[plugins.foo]
version = "1.0.0"
pin = true
]],
            tostring(rocks_toml)
        )
        vim.cmd.Rocks({ "unpin", "foo" })
        nio.sleep(2000) -- wait for rocks.toml to be written
        rocks_toml = parse_config()
        assert.same(
            [[
[plugins]
foo= "1.0.0"
]],
            tostring(rocks_toml)
        )
    end)
end)
