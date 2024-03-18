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

## :moon: Introduction

rocks.nvim revolutionizes Neovim plugin management by streamlining the way users
and developers handle plugins and dependencies.
Integrating directly with [`luarocks`](https://luarocks.org),
this plugin offers an automated approach that shifts the responsibility
of specifying dependencies and build steps from users to plugin authors.

### Why rocks.nvim?

The traditional approach to Neovim plugin management often places
an unjust burden on users.

Consider the following example using lazy.nvim:

```lua
{
  'foo/bar.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    {
      '4O4/reactivex', -- LuaRocks dependency
      build = function(plugin)
        -- post-install build step required to link the luarocks dependency
        vim.uv.fs_symlink(plugin.dir, plugin.dir .. "/lua", { dir = true })
      end,
    },
  },
  build = "make install" -- Post-install build step of the main plugin
}
```

This setup illustrates several pain points in the status quo:

- Manual dependency management:
  Users are often required to manually specify and manage dependencies.
- Breaking changes:
  Updates to a plugin's dependencies can lead to breaking changes for users.
- Platform-specific instructions:
  Build instructions and dependencies may vary by platform, adding complexity.
- Because of this horrible UX, plugin authors have been reluctant to
  add dependencies, preferring to copy/paste code instead.

rocks.nvim simplifies the above example to:

```
:Rocks install bar.nvim
```

Welcome to a new era of Neovim plugin management - where simplicity meets efficiency!

### Philosophy

rocks.nvim itself is designed based on the UNIX philosophy:
Do one thing well.

It doesn't dictate how you as a user should configure your plugins.
But there's an optional module for those seeking
additional configuration capabilities: [`rocks-config.nvim`](https://github.com/nvim-neorocks/rocks-config.nvim).

We have packaged [many Neovim plugins and tree-sitter parsers](https://luarocks.org/modules/neorocks)
for luarocks, and an increasing number of plugin authors
[have been publishing themselves](https://luarocks.org/labels/neovim?non_root=on).
Additionally, [`rocks-git.nvim`](https://github.com/nvim-neorocks/rocks-git.nvim)
ensures you're covered even when a plugin isn't directly available on LuaRocks.

## :pencil: Requirements

- An up-to-date `Neovim` nightly (>= 0.10) installation.
- The `git` command line utility.
- `wget` or `curl` (if running on a UNIX system) - required for the remote `:source` command to work.
- `netrw` enabled in your Neovim configuration - enabled by default but some configurations manually disable the plugin.

> [!IMPORTANT]
>
> If you are running on an esoteric architecture, `rocks.nvim` will
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
> - If you specify `dev` or `scm` as the version, luarocks will search the `dev`
>   manifest. This has the side-effect that it will prioritise `dev` versions
>   of any dependencies that aren't declared with version constraints.

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

[^1]: We only upload parsers which we can install in the NURR CI
      (tested on Linux).

When installing, rocks.nvim will also search our [rocks-binaries (dev)](https://nvim-neorocks.github.io/rocks-binaries-dev/)
server, which means you don't even need to compile many parsers
on your machine.

### Effortless installation for users

If you need a tree-sitter parser for syntax highlighting or other features,
you can easily install them with rocks.nvim: `:Rocks install tree-sitter-<lang>`.

They come bundled with queries, so once installed,
all you need to do is run `vim.treesitter.start()` to enable syntax highlighting[^3].

[^3]: You can put this in a `ftplugin/<filetype>.lua`, for example.
      [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) is
      still required for tree-sitter based folding, indentation, etc.,
      but you don't need to configure it to install any parsers.

<!-- Or, if you want something that comes with lots of tree-sitter parsers and -->
<!-- automatically configures nvim-treesitter for you, -->
<!-- check out our [`rocks-treesiter.nvim` module](https://github.com/nvim-neorocks/rocks-treesitter.nvim). -->

> [!WARNING]
>
> - Tree-sitter is an experimental feature of Neovim.
>   As is the case with nvim-treesitter,
>   please consider tree-sitter support in rocks.nvim experimental.
>
> - We are not affiliated with the nvim-treesitter maintainers.
>   If you are facing issues with tree-sitter support in rocks.nvim,
>   please don't bug them.

### Simplifying dependencies

For plugin developers, specifying a tree-sitter parser as a dependency
is now as straightforward as including it in their project's rockspec[^2].
This eliminates the need for manual parser management and ensures that
dependencies are automatically resolved and installed.

[^2]: [example](https://luarocks.org/modules/mrcjkb/neotest-haskell).

Example rockspec dependency specification:

```lua
dependencies = {
  "neotest",
  "tree-sitter-haskell"
}
```

## :package: Extending `rocks.nvim`

This plugin provides a Lua API for extensibility.
See [`:h rocks.api`](./doc/rocks.txt) for details.

Following are some examples:

- [`rocks-git.nvim`](https://github.com/nvim-neorocks/rocks-git.nvim):
  Adds the ability to install plugins from git.
- [`rocks-config.nvim`](https://github.com/nvim-neorocks/rocks-config.nvim):
  Adds an API for safely loading plugin configurations.
- [`rocks-dev.nvim`](https://github.com/nvim-neorocks/rocks-dev.nvim):
  Adds an API for developing and testing luarocks plugins locally.

To extend `rocks.nvim`, simply install a module with `:Rocks install`,
and you're good to go!

## :stethoscope: Troubleshooting

The `:Rocks log` command opens a log file for the current session,
which contains the `luarocks` stderr output, among other logs.

## :link: Related projects

- [luarocks-tag-release](https://github.com/nvim-neorocks/luarocks-tag-release):
  A GitHub action that automates publishing to luarocks.org
- [NURR](https://github.com/nvim-neorocks/nurr):
  A repository that publishes Neovim plugins and tree-sitter parsers
  to luarocks.org
- [luarocks.nvim](https://github.com/camspiers/luarocks):
  Adds basic support for installing lua rocks to [lazy.nvim](https://github.com/folke/lazy.nvim)

## :book: License

`rocks.nvim` is licensed under [GPLv3](./LICENSE).

## :green_heart: Contributing

Contributions are more than welcome!
See [CONTRIBUTING.md](./CONTRIBUTING.md) for a guide.
