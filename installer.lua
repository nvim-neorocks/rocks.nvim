local buffer = vim.api.nvim_create_buf(true, true)

vim.api.nvim_buf_set_name(buffer, "rocks.nvim installer")

vim.api.nvim_win_set_option(0, "conceallevel", 3)
vim.api.nvim_win_set_option(0, "concealcursor", "nv")
vim.api.nvim_win_set_buf(0, buffer)
vim.cmd([[
    syntax match Rocks /rocks\.nvim/
    hi Rocks gui=bold cterm=bold
]])

--- TODO(vhyrro): Add logic for when the screen is too small to display text.
local function resize_ui()
    vim.api.nvim_buf_set_option(buffer, "modifiable", true)
    local size = vim.api.nvim_win_get_width(0)

    vim.opt.textwidth = size % 2 == 0 and size or size - 1
    vim.cmd("%center")
    vim.api.nvim_buf_set_option(buffer, "modifiable", false)
end

local function create_title()
    local title = [[
 _ __ ___   ___| | _____   _ ____   _(_)_ __ ___
| '__/ _ \ / __| |/ / __| | '_ \ \ / / | '_ ` _ \
| | | (_) | (__|   <\__ \_| | | \ V /| | | | | | |
|_|  \___/ \___|_|\_\___(_)_| |_|\_/ |_|_| |_| |_|
]]

    local title_lines = vim.split(title, "\n", { plain = true, trimempty = true })

    -- Padding logic
    -- The following `do` block ensures that all lines are of equal width
    -- so the title gets centered appropriately.
    do
        local min_len = 0

        for _, line in ipairs(title_lines) do
            min_len = math.max(min_len, line:len())
        end

        for i, line in ipairs(title_lines) do
            title_lines[i] = title_lines[i] .. string.rep(" ", math.max(min_len - line:len() - 1, 0))
        end
    end

    local introduction = vim.split([[



Welcome to the rocks.nvim installer!
rocks.nvim is a modern approach to Neovim plugin management.


This page lists all of the most important tweakable aspects of the installation process.
To edit a value, move your cursor over it and modify the value using regular Neovim keybinds.
    ]], "\n", { plain = true })

    vim.api.nvim_buf_set_lines(buffer, 0, -1, true, vim.list_extend(title_lines, introduction))
    vim.api.nvim_buf_set_option(buffer, "modifiable", false)
end

local function install()
    vim.api.nvim_create_autocmd("VimResized", {
        buffer = buffer,
        callback = vim.schedule_wrap(resize_ui),
    })

    create_title()

    resize_ui()
end

vim.schedule(install)
