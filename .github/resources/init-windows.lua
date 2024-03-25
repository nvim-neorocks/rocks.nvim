vim.g.rocks_nvim = {
    rocks_path = vim.fs.joinpath(vim.fn.getcwd(), "rocks"),
    _log_level = vim.log.levels.TRACE,
}

local luarocks_path = {
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "share", "lua", "5.1", "?.lua"),
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
}
package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

local luarocks_cpath = {
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "lib", "lua", "5.1", "?.dll"),
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "lib64", "lua", "5.1", "?.dll"),
}
package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

vim.opt.runtimepath:append(
    vim.fs.joinpath(vim.g.rocks_nvim.rocks_path, "lib", "luarocks", "rocks-5.1", "rocks.nvim", "*")
)
