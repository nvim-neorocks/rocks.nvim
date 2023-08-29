-- Set up the Rocks autocommand

local function rocks(opts)
    local args = opts.fargs
    local operations = require("rocks.operations")

    if args[1] == "update" then
        operations.update()
    elseif args[1] == "sync" then
        operations.sync()
    end
end

vim.api.nvim_create_user_command("Rocks", rocks, {
    nargs = "+",
    desc = "Interacts with currently installed rocks",
    complete = function()
        -- TODO(vhyrro): Improve
        return { "update", "sync" }
    end,
})
