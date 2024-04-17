-- This script installs rocks.nvim through a bootstrapping process.
-- The process consists of the following:
-- - Configure luarocks to work flawlessly with Neovim
-- - Install luarocks
-- - Use the new luarocks installation to install `rocks.nvim`

-- The rocks.nvim plugin is already loaded via the vim.opt.runtimepath:append()
-- call in the `init.lua` bootstrapping script.

print("Hello")
