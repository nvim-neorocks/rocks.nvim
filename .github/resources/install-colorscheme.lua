local done = false
require("rocks.api").install("sweetie.nvim", "2.4.0", function()
    vim.uv.sleep(2000) -- Leave time for symlinks to be created
    done = true
end)
vim.fn.wait(60000, function()
    return done and 1 or 0
end)
