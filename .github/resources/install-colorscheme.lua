local done = false
require("rocks.api").install("sweetie.nvim", "2.4.0", function()
    done = true
end)
vim.fn.wait(60000, function()
    return done and 1 or 0
end)
