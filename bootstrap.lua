-- This script installs rocks.nvim through a bootstrapping process.
-- The process consists of the following:
-- - Configure luarocks to work flawlessly with Neovim
-- - Install luarocks
-- - Use the new luarocks installation to install `rocks.nvim`

-- The rocks.nvim plugin is already loaded via the vim.opt.runtimepath:append()
-- call in the `init.lua` bootstrapping script.

math.randomseed(os.time())

local config_data = vim.g.rocks_nvim or {}
local install_path = config_data.rocks_path or vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "rocks")
local temp_luarocks_path =
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.fs.joinpath(vim.fn.stdpath("run"), ("luarocks-%X"):format(math.random(256 ^ 7)))
local luarocks_binary = vim.fs.joinpath(temp_luarocks_path, "bin", "luarocks")

---@param dep string
---@return boolean is_missing
local function guard_set_up_luarocks_dependency_missing(dep)
    if vim.fn.executable(dep) ~= 1 then
        vim.notify(dep .. " must be installed to set up luarocks.", vim.log.levels.ERROR)
        return true
    end
    return false
end

--- Notify command output.
---@param msg string
---@param sc vim.SystemCompleted
---@param level integer|nil
local function notify_output(msg, sc, level)
    local function remove_shell_color(s)
        return tostring(s):gsub("\x1B%[[0-9;]+m", "")
    end
    vim.notify(
        table.concat({
            msg,
            sc and "stderr: " .. remove_shell_color(sc.stderr),
            sc and "stdout: " .. remove_shell_color(sc.stdout),
        }, "\n"),
        level
    )
end

--- Sets up luarocks for use with rocks.nvim
---@param path string
---@return boolean success
local function set_up_luarocks(path)
    if guard_set_up_luarocks_dependency_missing("git") then
        return false
    end
    if guard_set_up_luarocks_dependency_missing("make") then
        return false
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    local tempdir = vim.fs.joinpath(vim.fn.stdpath("run"), ("luarocks-%X"):format(math.random(256 ^ 7)))

    vim.notify("Downloading luarocks...")

    local sc = vim.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/luarocks/luarocks.git",
        tempdir,
    }):wait()

    if sc.code ~= 0 then
        notify_output("Cloning luarocks failed: ", sc, vim.log.levels.ERROR)
        return false
    end

    vim.notify("Configuring luarocks...")

    sc = vim.system({
        "sh",
        "configure",
        "--prefix=" .. path,
        "--lua-version=5.1",
        "--force-config",
    }, {
        cwd = tempdir,
    }):wait()

    if sc.code ~= 0 then
        notify_output("Configuring luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    vim.notify("Installing luarocks...")

    sc = vim.system({
        "make",
        "install",
    }, {
        cwd = tempdir,
    }):wait()

    if sc.code ~= 0 then
        notify_output("Installing luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    return true
end

assert(set_up_luarocks(temp_luarocks_path), "failed to install luarocks! Please try again :)")

vim.notify("Installing rocks.nvim...")

local sc = vim.system({
    luarocks_binary,
    "--lua-version=5.1",
    "--tree=" .. install_path,
    "--server='https://nvim-neorocks.github.io/rocks-binaries/'",
    "install",
    "rocks.nvim",
}):wait()

if sc.code ~= 0 then
    notify_output("Installing rocks.nvim failed:", sc, vim.log.levels.ERROR)
    return
end

vim.print("rocks.nvim installed successfully!")
