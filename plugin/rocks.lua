local config = require("rocks.config.internal")

-- Initialize rocks

local function bootstrap_install(name, version)
    local luarocks = require("rocks.luarocks")
    luarocks
        .cli({
            "install",
            name,
            version,
        })
        :wait()
end

local luarocks_path = {
    vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?.lua"),
    vim.fs.joinpath(config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
}
package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

local luarocks_cpath = {
    vim.fs.joinpath(config.rocks_path, "lib", "lua", "5.1", "?.so"),
    vim.fs.joinpath(config.rocks_path, "lib64", "lua", "5.1", "?.so"),
}
package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

vim.opt.runtimepath:append(vim.fs.joinpath(config.rocks_path, "lib", "luarocks", "rocks-5.1", "*", "*"))

-- Is the toml rock installed? No? Well let's install it now!
local is_toml_installed, _ = pcall(require, "toml")

if not is_toml_installed then
    vim.ui.select({ "Ok" }, {
        prompt = "Rocks: Installing the 'toml' and `toml-edit` dependencies via luarocks. This may require compiling C++ and Rust code, so it may take a while, please wait...",
    }, function(choice)
        if choice == nil then
            vim.cmd.qa()
        end

        vim.schedule(function()
            bootstrap_install("toml", "0.3.0-0")
            bootstrap_install("toml-edit", "0.1.4-1")
            bootstrap_install("nui.nvim", "0.2.0-1")
            vim.notify("Installation complete! Please restart your editor.")
        end)
    end)
end

-- Set up the Rocks user command

---@type { [string]: fun(args:string[]) }
local command_tbl = {
    update = function(_)
        require("rocks.operations").update()
    end,
    sync = function(_)
        require("rocks.operations").sync()
    end,
    install = function(args)
        if #args == 0 then
            vim.notify("Rocks install: Called without required package argument.", vim.log.levels.ERROR)
            return
        end
        local package, version = args[1], args[2]
        require("rocks.operations").add(package, version)
    end,
}

local function rocks(opts)
    local fargs = opts.fargs
    local cmd = fargs[1]
    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local command = command_tbl[cmd]
    if not command then
        vim.notify("Rocks: Unknown command: " .. cmd, vim.log.levels.ERROR)
        return
    end
    command(args)
end

vim.api.nvim_create_user_command("Rocks", rocks, {
    nargs = "+",
    desc = "Interacts with currently installed rocks",
    complete = function(arg_lead, cmdline, _)
        local commands = vim.tbl_keys(command_tbl)

        if cmdline:match("^Rocks%s+%w*$") then
            return vim.iter(commands)
                :filter(function(command)
                    return command:find(arg_lead) ~= nil
                end)
                :totable()
        end
    end,
})
