-- GENERAL TODOs: make resizing workw with windows

local buffer = vim.api.nvim_create_buf(false, true)
local window = vim.api.nvim_get_current_win()

vim.api.nvim_buf_set_name(buffer, "rocks.nvim installer")
vim.api.nvim_buf_set_option(buffer, "expandtab", true)

vim.api.nvim_win_set_option(window, "conceallevel", 3)
vim.api.nvim_win_set_option(window, "concealcursor", "nv")
vim.api.nvim_win_set_buf(window, buffer)
vim.cmd([[
    syntax match Rocks /rocks\.nvim/
    hi Rocks gui=bold cterm=bold
]])

vim.api.nvim_set_option_value("virtualedit", "all", {
    win = window,
})

-- local ns = vim.api.nvim_create_namespace("rocks.nvim/installer")

--- UTILITY FUNCTIONS

local function acquire_buffer_lock(id, callback)
    vim.api.nvim_buf_set_option(id, "modifiable", true)
    callback()
    vim.api.nvim_buf_set_option(id, "modifiable", false)
end

--- TODO(vhyrro): Add logic for when the screen is too small to display text.
local function resize_ui()
    acquire_buffer_lock(buffer, function()
        local size = vim.api.nvim_win_get_width(window)

        vim.opt.textwidth = size % 2 == 0 and size or size - 1
        vim.cmd("%center")
    end)
end

local function create_body()
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

    local introduction = vim.split(
        [[



Welcome to the rocks.nvim installer!
rocks.nvim is a modern approach to Neovim plugin management.


This page lists all of the most important tweakable aspects of the installation process.
To edit a value, move your cursor over it and modify the value using regular Neovim keybinds.

This installer supports using the mouse.
Once you start editing a value, you may exit it by pressing Enter or by clicking elsewhere.


Rocks installation path: [install_path:20]
    ]],
        "\n",
        { plain = true }
    )

    -- Replace all `[number]` with a string of `number` amount of spaces and a window in that location
    -- track all windows and their ranges. When the cursor moves into the specific position

    vim.api.nvim_buf_set_lines(buffer, 0, -1, true, vim.list_extend(title_lines, introduction))
    vim.api.nvim_buf_set_option(buffer, "modifiable", false)
end

local function install()
    vim.api.nvim_create_autocmd("VimResized", {
        buffer = buffer,
        callback = vim.schedule_wrap(resize_ui),
    })

    create_body()
    resize_ui()

    local input_fields = {}

    for i, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, true)) do
        local start, end_, name, width = line:find("%[([^:]+):([0-9]+)%]")
        if start then
            acquire_buffer_lock(buffer, function()
                vim.api.nvim_buf_set_text(buffer, i - 1, start - 1, i - 1, end_, { string.rep(" ", width) })
            end)

            local subbuffer = vim.api.nvim_create_buf(false, true)

            local win_id = vim.api.nvim_open_win(subbuffer, false, {
                width = tonumber(width),
                height = 1,
                row = 0,
                col = 0,
                border = "none",
                style = "minimal",
                focusable = false,
                fixed = false,
                relative = "win",
                win = window,
                bufpos = { i - 1, start - 1 },
            })

            input_fields[name] = {
                window = win_id,
                buffer = subbuffer,
                width = width,
                data = "",
            }

            vim.keymap.set({ "n", "i" }, "<CR>", function()
                vim.cmd.stopinsert()

                local current_cursor_pos = vim.api.nvim_win_get_cursor(window)
                current_cursor_pos[1] = current_cursor_pos[1] + 1
                vim.api.nvim_win_set_cursor(window, current_cursor_pos)
                vim.api.nvim_set_current_win(window)
            end, { buffer = subbuffer })

            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                buffer = subbuffer,
                callback = function()
                    input_fields[name].data = vim.api.nvim_buf_get_lines(subbuffer, 0, -1, true)[1]
                end,
            })
        end
    end

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = buffer,
        callback = function()
            local current_cursor_pos = vim.api.nvim_win_get_cursor(window)

            for _, data in pairs(input_fields) do
                local win_pos = vim.api.nvim_win_get_position(data.window)
                local width = data.width

                if
                    current_cursor_pos[1] - 1 == win_pos[1]
                    and (current_cursor_pos[2] >= win_pos[2] and current_cursor_pos[2] <= win_pos[2] + width)
                then
                    vim.api.nvim_set_current_win(data.window)
                end
            end
        end,
    })
end

vim.schedule(install)
