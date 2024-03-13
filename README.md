<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/nvim-neorocks/rocks.nvim">
    <img src="./rocks-header.svg" alt="rocks.nvim">
  </a>
  <p align="center">
    <br />
    <a href="./doc/rocks.txt"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/nvim-neorocks/rocks.nvim/issues/new?assignees=&labels=bug">Report Bug</a>
    ·
    <a href="https://github.com/nvim-neorocks/rocks.nvim/issues/new?assignees=&labels=enhancement">Request Feature</a>
    ·
    <a href="https://github.com/nvim-neorocks/rocks.nvim/discussions/new?category=q-a">Ask Question</a>
  </p>
  <p>
    <strong>
      A modern approach to <a href="https://neovim.io/">Neovim</a> plugin management!
    </strong>
  </p>
  <p>🌒</p>
</div>
<!-- markdownlint-restore -->

## :star2: Features

- `Cargo`-like `rocks.toml` file for declaring all your plugins.
- Name-based installation
  (` "nvim-neorg/neorg" ` becomes `:Rocks install neorg` instead).
- Automatic dependency and build script management.
- True semver versioning!
- Minimal, non-intrusive UI.
- Async execution.
- Extensible, with a Lua API.
  - [`rocks-git.nvim`](https://github.com/nvim-neorocks/rocks-git.nvim)
    for installing from git repositories.
  - [`rocks-config.nvim`](https://github.com/nvim-neorocks/rocks-config.nvim)
    for plugin configuration.
  - And more...
- Command completions for plugins and versions on luarocks.org.
- Binary rocks pulled from [rocks-binaries](https://nvim-neorocks.github.io/rocks-binaries/)
  so you don't have to compile them.

![demo](https://github.com/nvim-neorocks/rocks.nvim/assets/12857160/955c3ae7-c916-4a70-8fbd-4e28b7f0d77e)

## :pencil: Requirements

- An up-to-date `Neovim` nightly (>= 0.10) installation.
- The `git` command line utility.
- `wget` or `curl` (if running on a UNIX system) - required for the remote `:source` command to work.
- `netrw` enabled in your Neovim configuration - enabled by default but some configurations manually disable the plugin.

> [!IMPORTANT]
> If you are running on Windows or an esoteric architecture, `rocks.nvim` will
> attempt to compile its dependencies instead of pulling a prebuilt binary. For
> the process to succeed you must have a **C++17 parser** and **Rust
> toolchain** installed on your system.

## :hammer: Installation

### :zap: Installation script (recommended)

The days of bootstrapping and editing your configuration are over.
`rocks.nvim` can be installed directly through an interactive installer within Neovim.

We suggest starting nvim without loading RC files, such that already installed plugins do not interfere
with the installer:

```sh
nvim -u NORC -c "source https://raw.githubusercontent.com/nvim-neorocks/rocks.nvim/master/installer.lua"
```

> [!IMPORTANT]
>
> For security reasons, we recommend that you read `:help :source`
> and the installer code before running it so you know exactly what it does.

> [!TIP]
>
> To configure the luarocks installation to use a specific lua install,
> use environment variables `LUA_BINDIR=<Directory of lua binary>` and `LUA_BINDIR_SET=yes`.
>
> For example:
>
> `LUA_BINDIR="${XDG_BIN_DIR:-$HOME/.local/bin}" LUA_BINDIR_SET=yes nvim -u NORC -c "source ...`

## :books: Usage

### Installing rocks

You can install rocks with the `:Rocks install {rock} {version?}` command.

Arguments:

- `rock`: The luarocks package.
- `version`: Optional. Used to pin a rock to a specific version.

> [!NOTE]
>
> - The command provides fuzzy completions for rocks and versions on luarocks.org.
> - Installs the latest version if `version` is omitted.
> - This plugin keeps track of installed plugins in a `rocks.toml` file,
>   which you can commit to version control.

### Updating rocks

Running the `:Rocks update` command will attempt to update every available rock
if it is not pinned.

### Syncing rocks

The `:Rocks sync` command synchronizes the installed rocks with the `rocks.toml`.

> [!NOTE]
>
> - Installs missing rocks.
> - Ensures that the correct versions are installed.
> - Uninstalls unneeded rocks.

### Uninstalling rocks

To uninstall a rock and any of its dependencies,
that are no longer needed, run the `:Rocks prune {rock}` command.

> [!NOTE]
>
> - The command provides fuzzy completions for rocks that can safely
>   be pruned without breaking dependencies.

### Editing `rocks.toml`

The `:Rocks edit` command opens the `rocks.toml` file for manual editing.
Make sure to run `:Rocks sync` when you are done.

### Lazy loading plugins

By default, `rocks.nvim` will source all plugins at startup.
To prevent it from sourcing a plugin, you can specify `opt = true`
in the `rocks.toml` file.

For example:

```toml
[plugins]
neorg = { version = "1.0.0", opt = true }
```

or

```toml
[plugins.neorg]
version = "1.0.0"
opt = true
```

You can then load the plugin with the `:Rocks[!] packadd {rock}` command.

> [!NOTE]
>
> A note on loading rocks:
>
> Luarocks packages are installed differently than you are used to
> from Git repositories.
>
> Specifically, `luarocks` installs a rock's Lua API to the [`package.path`](https://neovim.io/doc/user/luaref.html#package.path)
> and the [`package.cpath`](https://neovim.io/doc/user/luaref.html#package.cpath).
> It does not have to be added to Neovim's runtime path
> (e.g. using `:Rocks packadd`), for it to become available.
> This does not impact Neovim's startup time.
>
> Runtime directories ([`:h runtimepath`](https://neovim.io/doc/user/options.html#'runtimepath')),
> on the other hand, are installed to a separate location.
> Plugins that utilise these directories may impact startup time
> (if it has `ftdetect` or `plugin` scripts), so you may or may
> not benefit from loading them lazily.

## :deciduous_tree: Enhanced tree-sitter support

We're revolutionizing the way Neovim users interact with tree-sitter parsers.
With the introduction of the [Neovim User Rocks Repository (NURR)](https://github.com/nvim-neorocks/nurr),
we have automated the packaging and publishing of many plugins and curated[^1] tree-sitter parsers
for luarocks, ensuring a seamless and efficient user experience.

[^1]: We only upload parsers which we can install in the NURR CI.

When installing, rocks.nvim will also search our [rocks-binaries](https://nvim-neorocks.github.io/rocks-binaries/)
server, which means you don't even need to compile many parsers
on your machine[^2].

[^2]: We currently do not provide binary rocks for parsers that need
      to have their sources generated using the tree-sitter CLI.

### Simplifying dependencies

For plugin developers, specifying a tree-sitter parser as a dependency
is now as straightforward as including it in their project's rockspec[^3].
This eliminates the need for manual parser management and ensures that
dependencies are automatically resolved and installed.

[^3]: [example](https://luarocks.org/modules/MrcJkb/neotest-haskell).

Example rockspec dependency specification:

```lua
dependencies = {
  "neotest",
  "tree-sitter-haskell"
}
```

### Effortless installation for users

If you need a tree-sitter parser for syntax highlighting or other features,
you can easily install them with rocks.nvim: `:Rocks install tree-sitter-<lang>`.

> [!IMPORTANT]
>
> You still need to install [nvim-treesitter](https://luarocks.org/modules/neovim/nvim-treesitter)
> for tree-sitter based syntax highlighting, injections, etc.,
> as the queries are not provided by the parsers.

## :package: Extending `rocks.nvim`

This plugin provides a Lua API for extensibility.
See [`:h rocks.api`](./doc/rocks.txt) for details.

Following are some examples:

- [`rocks-git.nvim`](https://github.com/nvim-neorocks/rocks-git.nvim):
  Adds the ability to install plugins from git.
- [`rocks-config.nvim`](https://github.com/nvim-neorocks/rocks-config.nvim):
  Adds an API for safely loading plugin configurations.

To extend `rocks.nvim`, simply install a module with `:Rocks install`,
and you're good to go!

## :stethoscope: Troubleshooting

The `:Rocks log` command opens a log file for the current session,
which contains the `luarocks` stderr output, among other logs.

## :book: License

`rocks.nvim` is licensed under [GPLv3](./LICENSE).

## :green_heart: Contributing

Contributions are more than welcome!
See [CONTRIBUTING.md](./CONTRIBUTING.md) for a guide.
