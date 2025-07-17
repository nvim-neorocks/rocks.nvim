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
    vim.fs.joinpath(vim.fn.stdpath("run") --[[@as string]], ("luarocks-%X"):format(math.random(256 ^ 7)))
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

---@param cmd string[]
---@param opts? vim.SystemOpts
---@return vim.SystemCompleted
local function exec(cmd, opts)
    ---@type boolean, vim.SystemObj | string
    local ok, so_or_err = pcall(vim.system, cmd, opts)
    if not ok then
        ---@cast so_or_err string
        return {
            code = 1,
            signal = 0,
            stderr = ([[
Failed to execute:
%s
%s]]):format(table.concat(cmd, " "), so_or_err),
        }
    end
    ---@cast so_or_err vim.SystemObj
    return so_or_err:wait()
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

    local tempdir =
        vim.fs.joinpath(vim.fn.stdpath("run") --[[@as string]], ("luarocks-%X"):format(math.random(256 ^ 7)))

    vim.notify("Downloading luarocks...")

    local sc = exec({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/luarocks/luarocks.git",
        tempdir,
    })

    if sc.code ~= 0 then
        notify_output("Cloning luarocks failed: ", sc, vim.log.levels.ERROR)
        return false
    end

    local luarocks_version = "v3.12.2"
    sc = exec({
        "git",
        "checkout",
        luarocks_version,
    }, {
        cwd = tempdir,
    })
    if sc.code ~= 0 then
        notify_output(("Checking out luarocks %s failed."):format(luarocks_version), sc, vim.log.levels.WARN)
    end

    vim.notify("Configuring luarocks...")

    sc = exec({
        "sh",
        "configure",
        "--prefix=" .. path,
        "--lua-version=5.1",
        "--force-config",
    }, {
        cwd = tempdir,
    })

    if sc.code ~= 0 then
        notify_output("Configuring luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    vim.notify("Installing luarocks...")

    sc = exec({
        "make",
        "install",
    }, {
        cwd = tempdir,
    })

    if sc.code ~= 0 then
        notify_output("Installing luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    return true
end

assert(set_up_luarocks(temp_luarocks_path), "failed to install luarocks! Please try again :)")

local rocks_binaries_supported_arch_map = {
    Darwin = {
        arm64 = "macosx-aarch64",
        aarch64 = "macosx-aarch64",
        x86_64 = "macosx-x86_64",
    },
    Linux = {
        x86_64 = "linux-x86_64",
    },
    Windows_NT = {
        x86_64 = "win32-x86_64",
    },
}
local uname = vim.uv.os_uname()
local supported_arch = rocks_binaries_supported_arch_map[uname.sysname][uname.machine]

local install_cmd = {
    luarocks_binary,
    "--lua-version=5.1",
    "--tree=" .. install_path,
    "install",
    "rocks.nvim",
}
if supported_arch then
    table.insert(install_cmd, 4, "--server='https://nvim-neorocks.github.io/rocks-binaries/'")
end
vim.notify("Installing rocks.nvim...")

local sc = exec(install_cmd)

if sc.code ~= 0 then
    notify_output("Installing rocks.nvim failed:", sc, vim.log.levels.ERROR)
    return
end

vim.print("rocks.nvim installed successfully!")
