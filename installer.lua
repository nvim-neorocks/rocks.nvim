---@author Vhyrro
---@license GPLv3

-- This file activates an installer window within Neovim that allows for a fully fledged `rocks.nvim` installation.
-- This file is usually sourced from an external hosting provider like Github.

-- GENERAL TODOs:
-- - Make resizing work with windows
-- - Remove some code duplication
-- - Make code work on all platforms
-- - Add proper error handling

local min_version = "0.10.0"
if vim.fn.has("nvim-" .. min_version) ~= 1 then
    error(("rocks.nvim requires Neovim >= %s"):format(min_version))
end

--- The buffer ID of the main UI
---@type number
local buffer = vim.api.nvim_create_buf(false, true)

--- The window ID of the main UI
---@type number
local window = vim.api.nvim_get_current_win()

-- STEP 1: Set up appropriate variables for newly created buffer.

vim.api.nvim_buf_set_name(buffer, "rocks.nvim installer")
vim.bo[buffer].expandtab = true

vim.wo[window].conceallevel = 3
vim.wo[window].concealcursor = "nv"
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
    vim.bo[id].modifiable = true
    callback()
    vim.bo[id].modifiable = false
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
Set up luarocks (recommended) ?: [setup_luarocks:6:{{true }}]

< OK >
    ]],
        "\n",
        { plain = true }
    )

    vim.api.nvim_buf_set_lines(buffer, 0, -1, true, vim.list_extend(title_lines, introduction))
    vim.bo[buffer].modifiable = false
end

---@param dep string
---@return boolean is_missing
local function guard_set_up_luarocks_dependency_missing(dep)
    if vim.fn.executable(dep) ~= 1 then
        vim.notify(dep .. " must be installed to set up luarocks.", vim.log.levels.ERROR)
        return true
    end
    return false
end

--- Notify command output.
---@param msg string
---@param sc vim.SystemCompleted
---@param level integer|nil
local function notify_output(msg, sc, level)
    local function remove_shell_color(s)
        return tostring(s):gsub("\x1B%[[0-9;]+m", "")
    end
    vim.notify(
        table.concat({
            msg,
            sc and "stderr: " .. remove_shell_color(sc.stderr),
            sc and "stdout: " .. remove_shell_color(sc.stdout),
        }, "\n"),
        level
    )
end

--- Sets up luarocks for use with rocks.nvim
---@param install_path string
---@return boolean success
local function set_up_luarocks(install_path)
    if guard_set_up_luarocks_dependency_missing("git") then
        return false
    end
    if guard_set_up_luarocks_dependency_missing("make") then
        return false
    end

    local tempdir =
        vim.fs.joinpath(vim.fn.stdpath("run") --[[@as string]], ("luarocks-%X"):format(math.random(256 ^ 7)))

    vim.notify("Downloading luarocks...")

    local sc = vim.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/luarocks/luarocks.git",
        tempdir,
    }):wait()

    if sc.code ~= 0 then
        notify_output("Cloning luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    vim.notify("Configuring luarocks...")

    sc = vim.system({
        "sh",
        "configure",
        "--prefix=" .. install_path,
        "--lua-version=5.1",
        "--force-config",
    }, {
        cwd = tempdir,
    }):wait()

    if sc.code ~= 0 then
        notify_output("Configuring luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    vim.notify("Installing luarocks...")

    sc = vim.system({
        "make",
        "install",
    }, {
        cwd = tempdir,
    }):wait()

    if sc.code ~= 0 then
        notify_output("Installing luarocks failed.", sc, vim.log.levels.ERROR)
        return false
    end

    return true
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

    ---@alias position { [1]: integer, [2]: integer }
    ---@alias input_field {window: number, buffer: number, width: number, content: string, position: position}

    --- Stores all of the input fields (window IDs, buffer IDs, content)
    ---@type {[string]: input_field}
    local input_fields = {}

    for i, line in ipairs(vim.api.nvim_buf_get_lines(buffer, 0, -1, true)) do
        -- Try to find an input declaration and parse it.
        ---@type integer|nil, integer|nil, string, number, string
        local start, end_, name, width, default_value = line:find("%[([^:]+):([0-9]+):%{%{(.+)%}%}%]")

        if start and end_ then
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
            vim.wo[win_id].wrap = false

            input_fields[name] = {
                window = win_id,
                position = {
                    i - 1,
                    start - 1,
                },
                buffer = subbuffer,
                width = width,
                content = default_value,
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
                    input_fields[name].content = vim.api.nvim_buf_get_lines(subbuffer, 0, -1, true)[1]
                end,
            })
        end
    end

    -- If the user moves their cursor into the area of a window then move the cursor /into/ that
    -- window. This allows editable parts of text in an otherwise uneditable buffer.
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = buffer,
        callback = function()
            if not vim.api.nvim_win_is_valid(window) then
                return true
            end

            local current_cursor_pos = vim.api.nvim_win_get_cursor(window)

            -- Go through every active input field and see if we are in its area.
            for _, data in pairs(input_fields) do
                if not vim.api.nvim_win_is_valid(data.window) then
                    return true
                end

                local win_pos = data.position
                local width = data.width

                if
                    current_cursor_pos[1] - 1 == win_pos[1]
                    and (current_cursor_pos[2] >= win_pos[2] and current_cursor_pos[2] < win_pos[2] + width)
                then
                    vim.api.nvim_set_current_win(data.window)
                end
            end
        end,
    })

    vim.keymap.set("n", "<CR>", function()
        local cursor = vim.api.nvim_win_get_cursor(0)[1]
        local line = vim.trim(vim.api.nvim_buf_get_lines(0, cursor - 1, cursor, true)[1])

        if line == "< OK >" then
            local install_path = input_fields.install_path.content
            local setup_luarocks = input_fields.setup_luarocks.content == "true"
            local temp_luarocks_path =
                vim.fs.joinpath(vim.fn.stdpath("run") --[[@as string]], ("luarocks-%X"):format(math.random(256 ^ 7)))

            local luarocks_binary = "luarocks"

            if setup_luarocks then
                local success = set_up_luarocks(temp_luarocks_path)
                if not success then
                    return
                end
                luarocks_binary = vim.fs.joinpath(temp_luarocks_path, "bin", "luarocks")
            elseif vim.fn.executable(luarocks_binary) ~= 1 then
                vim.notify(
                    luarocks_binary
                        .. " not found. Please ensure luarocks is installed or configure the installer to setup luarocks automatically",
                    vim.log.levels.ERROR
                )
                return
            end

            vim.notify("Installing rocks.nvim...")
            local sc = vim.system({
                luarocks_binary,
                "--lua-version=5.1",
                "--tree=" .. install_path,
                "--server='https://nvim-neorocks.github.io/rocks-binaries/'",
                "install",
                "rocks.nvim",
            }):wait()

            if sc.code ~= 0 then
                notify_output("Installing rocks.nvim failed:", sc, vim.log.levels.ERROR)
                return
            end

            for _, data in pairs(input_fields) do
                pcall(vim.api.nvim_buf_delete, data.buffer, { force = true })
                pcall(vim.api.nvim_win_close, data.window, true)
            end

            acquire_buffer_lock(buffer, function()
                local install_path_rel = install_path:gsub(vim.env.HOME, "")

                vim.api.nvim_buf_set_lines(buffer, 0, -1, true, {
                    "INSTALLATION COMPLETE",
                    "",
                    "You are almost ready! Please take the following code snippet and paste it in your `init.lua`.",
                    "The code has already been copied to your clipboard:",
                    ">lua",
                    "    local rocks_config = {",
                    '        rocks_path = vim.env.HOME .. "' .. install_path_rel .. '",',
                    "    }",
                    "    ",
                    "    vim.g.rocks_nvim = rocks_config",
                    "    ",
                    "    local luarocks_path = {",
                    '        vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),',
                    '        vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),',
                    "    }",
                    '    package.path = package.path .. ";" .. table.concat(luarocks_path, ";")',
                    "    ",
                    "    local luarocks_cpath = {",
                    '        vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.so"),',
                    '        vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.so"),',
                    "        -- Remove the dylib and dll paths if you do not need macos or windows support",
                    '        vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.dylib"),',
                    '        vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.dylib"),',
                    '        vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.dll"),',
                    '        vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.dll"),',
                    "    }",
                    '    package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")',
                    "    ",
                    '    vim.opt.runtimepath:append(vim.fs.joinpath(rocks_config.rocks_path, "lib", "luarocks", "rocks-5.1", "rocks.nvim", "*"))',
                    "<",
                    "Thank you for installing rocks.nvim!",
                    "",
                    "<< OPEN INIT.LUA >>",
                })

                local size = vim.api.nvim_win_get_width(window)

                vim.opt.textwidth = size % 2 == 0 and size or size - 1
                vim.cmd("1center")
                vim.cmd("$-2,$center")

                vim.fn.setreg('"', {
                    "local rocks_config = {",
                    '    rocks_path = vim.env.HOME .. "' .. install_path_rel .. '",',
                    "}",
                    "",
                    "vim.g.rocks_nvim = rocks_config",
                    "",
                    "local luarocks_path = {",
                    '    vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),',
                    '    vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),',
                    "}",
                    'package.path = package.path .. ";" .. table.concat(luarocks_path, ";")',
                    "",
                    "local luarocks_cpath = {",
                    '    vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.so"),',
                    '    vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.so"),',
                    "    -- Remove the dylib and dll paths if you do not need macos or windows support",
                    '    vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.dylib"),',
                    '    vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.dylib"),',
                    '    vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.dll"),',
                    '    vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.dll"),',
                    "}",
                    'package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")',
                    "",
                    'vim.opt.runtimepath:append(vim.fs.joinpath(rocks_config.rocks_path, "lib", "luarocks", "rocks-5.1", "*", "*"))',
                    ---@diagnostic disable-next-line: param-type-mismatch
                }, "l")

                vim.bo[buffer].filetype = "help"
            end)
        elseif line == "<< OPEN INIT.LUA >>" then
            vim.cmd.edit(vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "init.lua"))
            vim.cmd("write ++p")
            pcall(vim.api.nvim_buf_delete, buffer, { force = true })
        end
    end, { buffer = 0 })
end

vim.schedule(install)
