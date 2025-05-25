vim.env.PLENARY_TEST_TIMEOUT = 60000

local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}

describe("plugin initialization", function()
    --
    local notify_once = stub(vim, "notify_once")
    local notify = stub(vim, "notify")
    local deprecate = stub(vim, "deprecate")

    local cwd = vim.fn.getcwd()
    local plugin_script = vim.fs.joinpath(cwd, "plugin", "rocks.lua")
    vim.cmd.source(plugin_script)
    it("emits no notifications", function()
        assert.True(vim.g.loaded_rocks_nvim)
        if not pcall(assert.stub(notify_once).called_at_most, 0) then
            -- this will fail, outputting the arguments
            assert.stub(notify).called_with(nil)
        end
        if not pcall(assert.stub(notify).called_at_most, 0) then
            assert.stub(notify).called_with(nil)
        end
    end)
    it("emits no deprecation warnings", function()
        if not pcall(assert.stub(deprecate).called_at_most, 0) then
            assert.stub(deprecate).called_with(nil)
        end
    end)
end)
