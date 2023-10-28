[<img src="https://raw.githubusercontent.com/luarocks/luarocks-logos/master/luarocks_logo_only.png" align="right" width="144" />](https://luarocks.org/)
<img src="https://pngfre.com/wp-content/uploads/heart-87-1024x849.png" align="right" width="104" />
[<img src="https://neovim.io/logos/neovim-mark-flat.png" align="right" width="114" />](https://neovim.io/)

# `rocks.nvim`

A modern approach to Neovim plugin management.

> **Note**
> The following plugin is perfectly usable, but its user interfaces are a **work in progress**.
>
> They will be fledged out soon! :)

## :star2: Features

- `Cargo`-like `rocks.toml` file for declaring all your plugins.
- Name-based installation (`use "nvim-neorg/neorg"` becomes `:Rocks install neorg` instead).
- Automatic dependency and build script management.
- True semver versioning!
- (WIP) Automatic running of test suites.

## :pencil: Requirements

- An up-to-date `Neovim` nightly (>= 0.10) installation.
- A C/C++ compiler of your choice (must be compatible with `C++17`!) + [`CMake`](https://cmake.org/).
- [`rust`](https://www.rust-lang.org/) toolchain (recommended latest stable version).
- [`luarocks`](https://luarocks.org/) installed on your system and accessible in your shell.

## :hammer: Installation

### :snowflake: Nix

<!-- Nix users have a skill issue here what else can I say.
Just joking - add an entry for nix users as well. -->

TODO...

### :zap: Installation script (recommended)

The days of bootstrapping and editing your configuration are over. rocks.nvim can be installed directly through an interactive installer within Neovim.

You just have to run the following command inside your editor and the installer will do the rest!
```vim
:source https://raw.githubusercontent.com/nvim-neorocks/rocks.nvim/installer/installer.lua
```

> **Important**
> For security reasons, we recommend that you read `:help :source` and the installer code before running it so you know exactly what it does.

## :books: Usage

TODO...

## :book: License

rocks.nvim is licensed under GPLv3.
