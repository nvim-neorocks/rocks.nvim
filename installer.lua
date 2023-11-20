---@author Vhyrro
---@license GPLv3

-- This file activates an installer window within Neovim that allows for a fully fledged `rocks.nvim` installation.
-- This file is usually source from an external hosting provider like Github.

-- GENERAL TODOs: make resizing work with windows

--- The buffer ID of the main UI
---@type number
local buffer = vim.api.nvim_create_buf(false, true)

--- The window ID of the main UI
---@type number
local window = vim.api.nvim_get_current_win()

-- STEP 1: Set up appropriate variables for newly created buffer.

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

-----------------------------------------------------------------

--- Temporarily sets a buffer to modifiable before running a callback
--- and making the buffer unmodifiable again.
---@param id number #The buffer ID of the buffer to unlock
---@param callback fun() #The callback to execute
local function acquire_buffer_lock(id, callback)
    vim.api.nvim_buf_set_option(id, "modifiable", true)
    callback()
    vim.api.nvim_buf_set_option(id, "modifiable", false)
end

--- Resizes the user interface and readjusts all text and other UI elements.
--- TODO(vhyrro): Add logic for when the screen is too small to display text.
local function resize_ui()
    acquire_buffer_lock(buffer, function()
        local size = vim.api.nvim_win_get_width(window)

        vim.opt.textwidth = size % 2 == 0 and size or size - 1
        vim.cmd("%center")
    end)
end

--- Creates the main banner and introduction text for the installer.
local function create_body()
    local title = [[
 _ __ ___   ___| | _____   _ ____   _(_)_ __ ___
| '__/ _ \ / __| |/ / __| | '_ \ \ / / | '_ ` _ \
| | | (_) | (__|   <\__ \_| | | \ V /| | | | | | |
|_|  \___/ \___|_|\_\___(_)_| |_|\_/ |_|_| |_| |_|
]]

    ---@type string[]
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

    --- The introductory text for the `rocks.nvim` installer.
    --- Segments where input should be permitted are defined by the following syntax:
    ---
    ---     [name:length:{{lua_code()}}]
    ---
    --- The return value of the executed lua becomes the default value for that entry.
    --- The default value section may be ommitted.
    ---@type string[]
    local introduction = vim.split(
        [[



Welcome to the rocks.nvim installer!
rocks.nvim is a modern approach to Neovim plugin management.


This page lists all of the most important tweakable aspects of the installation process.
To edit a value, move your cursor over it and modify the value using regular Neovim keybinds.
When you are ready, press <CR> on the OK button.

This installer supports using the mouse.
Once you start editing a value, you may exit it by pressing Enter or by clicking elsewhere.

-------------------------------------------------------------------------------------------

Rocks installation path: [install_path:50:{{vim.fs.joinpath(vim.fn.stdpath('data'), "rocks")}}]

Should rocks.nvim set up luarocks?: [setup_luarocks:5:{{vim.fn.executable('luarocks') == 0}}]

<OK>
    ]],
        "\n",
        { plain = true }
    )

    vim.api.nvim_buf_set_lines(buffer, 0, -1, true, vim.list_extend(title_lines, introduction))
    vim.api.nvim_buf_set_option(buffer, "modifiable", false)
end

--- Sets up luarocks for use with rocks.nvim
local function set_up_luarocks(install_path)
    -- TODO: Check running OS here
    -- TODO: Error checking

    local tempdir = vim.fs.joinpath(vim.fn.stdpath("run"), "luarocks")

    vim.system({
        "git",
        "clone",
        "https://github.com/luarocks/luarocks.git",
        tempdir,
        "--depth=1",
    }):wait()

    vim.system({
        "sh",
        "configure",
        "--prefix=" .. install_path,
        "--lua-version=5.1",
        "--force-config",
    }, {
        cwd = tempdir,
    }):wait()

    vim.system({
        "make",
        "install",
    }, {
        cwd = tempdir,
    }):wait()
end

--- The main function of the installer.
local function install()
    vim.api.nvim_create_autocmd("VimResized", {
        buffer = buffer,
        callback = vim.schedule_wrap(resize_ui),
    })

    create_body()
    resize_ui()

    -- This section goes through all input declarations and parses them, creating new windows
    -- where applicable (see the `introduction` variable in the `create_body` function).
    ---@see create_body

    --- Stores all of the input fields (window IDs, buffer IDs, content)
    ---@type table<{window: number, buffer: number, width: number, content: string}>
    local input_fields = {}

    for i, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, true)) do
        -- Try to find an input declaration and parse it.
        ---@type number, number, string, number, string
        local start, end_, name, width, default_value = line:find("%[([^:]+):([0-9]+):%{%{(.+)%}%}%]")

        if start then
            -- Attempt to execute the code that will give us the default value
            default_value = assert(loadstring("return tostring(" .. default_value .. ")"))()

            -- Create necessary padding for the input window and recenter the line where we placed the new window.
            acquire_buffer_lock(buffer, function()
                vim.api.nvim_buf_set_text(buffer, i - 1, start - 1, i - 1, end_, { string.rep("_", width) })

                vim.cmd(tostring(i) .. "center")
                local difference = math.floor((width - (end_ - start)) / 2)

                start = start - difference
                end_ = end_ - difference
            end)

            -- Create a subbuffer for the input window which will contain editable text.
            local subbuffer = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(subbuffer, 0, -1, true, { default_value })

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
                data = default_value,
            }

            vim.keymap.set({ "n", "i" }, "<CR>", function()
                vim.cmd.stopinsert()

                local current_cursor_pos = vim.api.nvim_win_get_cursor(window)
                current_cursor_pos[1] = current_cursor_pos[1] + 1
                vim.api.nvim_win_set_cursor(window, current_cursor_pos)
                vim.api.nvim_set_current_win(window)
            end, { buffer = subbuffer })

            -- Every time the value within the input window changes also update the data
            -- in the input_fields table to reflect that data.
            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                buffer = subbuffer,
                callback = function()
                    input_fields[name].data = vim.api.nvim_buf_get_lines(subbuffer, 0, -1, true)[1]
                end,
            })
        end
    end

    -- If the user moves their cursor into the area of a window then move the cursor /into/ that
    -- window. This allows editable parts of text in an otherwise uneditable buffer.
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = buffer,
        callback = function()
            local current_cursor_pos = vim.api.nvim_win_get_cursor(window)

            -- Go through every active input field and see if we are in its area.
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

    vim.keymap.set("n", "<CR>", function()
        local cursor = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.trim(vim.api.nvim_buf_get_lines(0, cursor - 1, cursor, true)[1])

        if line == "<OK>" then
            local install_path = input_fields.install_path.data
            local setup_luarocks = input_fields.setup_luarocks.data == "true"

            local luarocks_binary = "luarocks"

            if setup_luarocks then
                set_up_luarocks(install_path)
                luarocks_binary = vim.fs.joinpath(install_path, "bin", "luarocks")
            end

            vim.system({
                luarocks_binary,
                "--lua-version=5.1",
                "--tree=" .. install_path,
                "install",
                "rocks.nvim",
            }):wait()

            vim.print("Installation successful!")
        end
    end, { buffer = 0 })
end

vim.schedule(install)
