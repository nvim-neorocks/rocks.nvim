local tempdir = vim.fn.tempname()
local rtp_dir = vim.fs.joinpath(tempdir, "rtp")
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}

describe("hooks", function()
    it("modifiers and actions", function()
        local config = require("rocks.config.internal")
        -- Test sync without any rocks
        local config_content = [[
[plugins]
rocks-modifier.nvim = "1.0.0"
rocks-action.nvim = "1.0.0"
]]
        local fh = assert(io.open(config.config_path, "w"), "Could not open rocks.toml for writing")
        fh:write(config_content)
        fh:close()
        local lua_dir = vim.fs.joinpath(rtp_dir, "lua")
        local modifier_hook_dir = vim.fs.joinpath(lua_dir, "rocks-modifier", "rocks", "hooks")
        local action_hook_dir = vim.fs.joinpath(lua_dir, "rocks-action", "rocks", "hooks")
        vim.system({ "mkdir", "-p", modifier_hook_dir }):wait()
        vim.system({ "mkdir", "-p", action_hook_dir }):wait()
        local modifier_hook_content = [[
return {
    type = "RockSpecModifier",
    hook = function(rock)
        rock.opt = true
        return rock
    end,
}
]]
        fh = assert(
            io.open(vim.fs.joinpath(modifier_hook_dir, "preload.lua"), "w"),
            "Could not open modifier hook file for writing"
        )
        fh:write(modifier_hook_content)
        fh:close()
        local action_hook_content = [[
return {
    type = "Action",
    hook = function()
      vim.g.action_hook_sourced = true
    end,
}
]]
        fh = assert(
            io.open(vim.fs.joinpath(action_hook_dir, "preload.lua"), "w"),
            "Could not open action hook file for writing"
        )
        fh:write(action_hook_content)
        fh:close()
        vim.opt.runtimepath:append(rtp_dir)
        local user_rocks = config.get_user_rocks()
        assert.is_nil(vim.g.action_hook_sourced)
        vim.iter(user_rocks):each(function(_, rock)
            assert.is_nil(rock.opt)
        end)
        require("rocks.api.hooks").run_preload_hooks(user_rocks)
        vim.iter(user_rocks):each(function(_, rock)
            assert.True(rock.opt)
        end)
        assert.True(vim.g.action_hook_sourced)
        user_rocks = config.get_user_rocks()
        vim.iter(user_rocks):each(function(_, rock)
            assert.True(rock.opt)
        end)
    end)
end)
