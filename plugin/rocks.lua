-- Set up the Rocks autocommand

local function rocks(opts)
    local args = opts.fargs
    local operations = require("rocks.operations")

    if args[1] == "update" then
        operations.update()
    elseif args[1] == "sync" then
        operations.sync()
    elseif args[1] == "install" then
        operations.add(args[2], args[3])
    end
end

vim.api.nvim_create_user_command("Rocks", rocks, {
    nargs = "+",
    desc = "Interacts with currently installed rocks",
    complete = function(arg_lead, cmdline, _)
        local commands = { "update", "sync", "install" }

        if cmdline:match("^Rocks%s+%w*$") then
            return vim.iter(commands)
                :filter(function(command)
                    return command:find(arg_lead) ~= nil
                end)
                :totable()
        end
    end,
})
