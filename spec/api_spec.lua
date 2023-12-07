local api = require("rocks.api")
local spy = require("luassert.spy")
describe("Lua API", function()
    it("fuzzy_filter_rocks_table", function()
        local result = api.fuzzy_filter_rock_tbl({
            neorg = { name = "neorg", version = "1.0.0" },
            foo = { name = "foo", version = "1.0.0" },
        }, "nrg")
        assert.same({ neorg = { name = "neorg", version = "1.0.0" } }, result)
    end)
    it("register_rocks_subcommand", function()
        require("rocks.commands").create_commands()
        local s = spy.new(function() end)
        local cmd = {
            impl = function(args)
                s(args)
            end,
        }
        api.register_rocks_subcommand("test", cmd)
        vim.cmd.Rocks({ "test", "foo" })
        assert.spy(s).called_with({ "foo" })
    end)
end)
