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
    complete = function()
        -- TODO(vhyrro): Improve
        return { "update", "sync", "install" }
    end,
})
