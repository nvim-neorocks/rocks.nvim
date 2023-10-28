local buffer = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_name(buffer, "rocks.nvim installer")

vim.api.nvim_create_autocmd("BufEnter", {
    buffer = buffer,
    callback = function()
        vim.notify("It's installation time")
    end,
})

vim.api.nvim_win_set_buf(0, buffer)
