local buffer = vim.api.nvim_create_buf(true, true)
vim.api.nvim_win_set_buf(0, buffer)

vim.api.nvim_create_autocmd("BufEnter", {
    buffer = buffer,
    callback = function()
        vim.notify("Installation time")
    end,
})
