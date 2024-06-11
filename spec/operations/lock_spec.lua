---@diagnostic disable: inject-field

local tempdir = vim.fn.tempname()
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", tempdir }):wait()
vim.g.rocks_nvim = {
    luarocks_binary = "luarocks",
    rocks_path = tempdir,
    config_path = vim.fs.joinpath(tempdir, "rocks.toml"),
}

local lock = require("rocks.operations.lock")
local fs = require("rocks.fs")
local config = require("rocks.config.internal")
local helpers = require("rocks.operations.helpers")
local state = require("rocks.state")
local nio = require("nio")

vim.env.PLENARY_TEST_TIMEOUT = 60000 * 5

describe("operations.lock", function()
    nio.tests.it("Lockfile roundtrip", function()
        config.lockfile_path = assert(vim.fn.tempname(), "Could not create tempname")
        local lockfile_content = [[
[neorg]
"pathlib.nvim" = "2.2.0-1"
"plenary.nvim" = "0.1.4-1"
say = "1.4.1-3"
"nui.nvim" = "0.3.0-1"
"lua-utils.nvim" = "1.0.2-1"
luassert = "1.9.0-1"
nvim-nio = "1.7.0-1"
[neotest]
luassert = "1.9.0-1"
say = "1.4.1-3"
"plenary.nvim" = "0.1.4-1"
]]
        local fh = assert(io.open(config.lockfile_path, "w"), "Could not open rocks.lock for writing")
        fh:write(lockfile_content)
        fh:close()
        assert.same(lockfile_content, fs.read_or_create(config.lockfile_path, ""))
        local neorg_lockfile = assert(lock.create_luarocks_lock("neorg"), "Failed to create neorg luarocks.lock")
        vim.fs.joinpath(vim.fn.stdpath("run") --[[@as string]], ("luarocks-lock-%X"):format(math.random(256 ^ 7)))
        assert(fs.mkdir_p(tempdir), "Failed to create tempdir " .. tempdir)
        local neorg_rtp_path = vim.fs.joinpath(tempdir, "neorg", "1.0.0-1")
        local neotest_rtp_path = vim.fs.joinpath(tempdir, "neotest", "1.0.0-1")

        fs.mkdir_p(neorg_rtp_path)
        local future = nio.control.future()
        vim.system({ "mv", neorg_lockfile, vim.fs.joinpath(neorg_rtp_path, "luarocks.lock") }, nil, function()
            future.set(true)
        end)
        future.wait()
        future = nio.control.future()
        vim.schedule(function()
            vim.opt.runtimepath:append(neorg_rtp_path)
            future.set(true)
        end)
        future.wait()
        local neotest_lockfile = assert(lock.create_luarocks_lock("neotest"), "Failed to create neotest luarocks.lock")
        fs.mkdir_p(neotest_rtp_path)
        future = nio.control.future()
        vim.system({ "mv", neotest_lockfile, vim.fs.joinpath(neotest_rtp_path, "luarocks.lock") }, nil, function()
            future.set(true)
        end)
        future.wait()
        future = nio.control.future()
        vim.schedule(function()
            vim.opt.runtimepath:append(neotest_rtp_path)
            future.set(true)
        end)
        future.wait()
        -- Reset lockfile path
        config.lockfile_path = assert(vim.fn.tempname(), "Could not create tempname")
        lock.update_lockfile()
        nio.sleep(2000)
        future = nio.control.future()
        vim.schedule(function()
            vim.opt.runtimepath:remove(neorg_rtp_path)
            vim.opt.runtimepath:remove(neotest_rtp_path)
            future.set(true)
        end)
        future.wait()
        local roundtrip_content = fs.read_or_create(config.lockfile_path, "")
        local result = require("toml_edit").parse_as_tbl(roundtrip_content)
        local expected = {
            neorg = {
                ["nvim-nio"] = "1.7.0-1",
                luassert = "1.9.0-1",
                ["lua-utils.nvim"] = "1.0.2-1",
                ["nui.nvim"] = "0.3.0-1",
                say = "1.4.1-3",
                ["plenary.nvim"] = "0.1.4-1",
                ["pathlib.nvim"] = "2.2.0-1",
            },
            neotest = {
                ["plenary.nvim"] = "0.1.4-1",
                luassert = "1.9.0-1",
                say = "1.4.1-3",
            },
        }
        assert.same(expected, result)
    end)
    nio.tests.it("Excludes lua and dev dependencies", function()
        local luarocks_lockfile_content = [[
return {
   dependencies = {
      lua = "5.1-1",
      luassert = "1.9.0-1",
      ["plenary.nvim"] = "scm-1",
      say = "1.4.1-3"
   },
}
]]
        tempdir = vim.fn.tempname()
        local neotest_rtp_path = vim.fs.joinpath(tempdir, "neotest", "1.0.0-1")
        fs.mkdir_p(neotest_rtp_path)
        local luarocks_lockfile_path = vim.fs.joinpath(neotest_rtp_path, "luarocks.lock")
        local fh = assert(io.open(luarocks_lockfile_path, "w"), "Could not open luarocks.lock for writing")
        fh:write(luarocks_lockfile_content)
        fh:close()
        local future = nio.control.future()
        vim.schedule(function()
            vim.opt.runtimepath:append(neotest_rtp_path)
            future.set(true)
        end)
        future.wait()
        config.lockfile_path = assert(vim.fn.tempname(), "Could not create tempname")
        lock.update_lockfile()
        nio.sleep(2000)
        local lockfile_content = fs.read_or_create(config.lockfile_path, "")
        local result = require("toml_edit").parse_as_tbl(lockfile_content)
        local expected = {
            neotest = {
                luassert = "1.9.0-1",
                say = "1.4.1-3",
            },
        }
        assert.same(expected, result)
    end)
    nio.tests.it("install installs pinned dependencies", function()
        local lockfile_content = [[
["oil.nvim"]
"nvim-web-devicons" = "0.99-1"
]]
        config.lockfile_path = assert(vim.fn.tempname(), "Could not create tempname")
        local fh = assert(io.open(config.lockfile_path, "w"), "Could not open rocks.lock for writing")
        fh:write(lockfile_content)
        fh:close()
        helpers.install({ name = "oil.nvim", version = "2.7.0" }, { use_lockfile = true }).wait()
        local installed_rocks = state.installed_rocks()
        assert.same({
            name = "nvim-web-devicons",
            version = "0.99",
        }, installed_rocks["nvim-web-devicons"])
    end)
end)
