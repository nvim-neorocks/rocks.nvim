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
