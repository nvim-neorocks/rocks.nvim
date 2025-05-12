<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/nvim-neorocks/lux.nvim">
    <img src="./lux-header.svg" alt="lux.nvim">
  </a>
  <p align="center">
    <br />
    <a href="./doc/lux.txt"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/nvim-neorocks/lux.nvim/issues/new?assignees=&labels=bug">Report Bug</a>
    ·
    <a href="https://github.com/nvim-neorocks/lux.nvim/issues/new?assignees=&labels=enhancement">Request Feature</a>
    ·
    <a href="https://github.com/nvim-neorocks/lux.nvim/discussions/new?category=q-a">Ask Question</a>
  </p>
  <p>
    <strong>
      A modern approach to <a href="https://neovim.io/">Neovim</a> plugin management
    </strong>
  </p>
  <p>🌒</p>
</div>
<!-- markdownlint-restore -->

## :star2: Features

- Automatic dependency and build script management.
- `Cargo`-like `lux.toml` file for declaring all your plugins.
- Simple and intuitive commands, just run `:Lux add myplugin`!
- Minimal, non-intrusive UI.
- Async execution for maximum speed.
- Supports [multiple versions of the same dependency](https://github.com/luarocks/luarocks/wiki/Using-LuaRocks#multiple-versions-using-the-luarocks-package-loader).
- Extensible, with a Lua API.
  - [`lux-config.nvim`](https://github.com/nvim-neorocks/lux-config.nvim)
    for plugin configuration.
  - [`lux-lazy.nvim`](https://github.com/nvim-neorocks/lux-lazy.nvim)
    for lazy-loading.
  - [`lux-treesitter.nvim`](https://github.com/nvim-neorocks/lux-treesitter.nvim)
    for automatic tree-sitter parser management.
  - And [more...](https://github.com/topics/lux-nvim)
- Command completions for plugins and versions on luarocks.org.
- Binary packages pulled from [lux-binaries](https://nvim-neorocks.github.io/lux-binaries/)
  so you don't have to compile them.

![demo](https://github.com/nvim-neorocks/lux.nvim/assets/12857160/ce678546-76a7-4fdc-b822-e43d51652681)

## :moon: Introduction

lux.nvim revolutionizes Neovim plugin management by streamlining the way users
and developers handle plugins and dependencies.
Integrating directly with [`luarocks`](https://luarocks.org),
this plugin offers an automated approach that shifts the responsibility
of specifying dependencies and build steps from users to plugin authors.

### :grey_question: Why lux.nvim

The traditional approach to Neovim plugin management often places
an unjust burden on users, by requiring them to declare dependencies and
build instructions manually.

This comes with several pain points:

- **Breaking changes:**
  Updates to a plugin's dependencies or build instructions
  can lead to breaking changes for users.
- **Platform-specific complexity:**
  Both dependencies and build instructions may vary by platform,
  adding complexity for users.
- **Poor user experience:**
  Because of this horrible UX, plugin authors have been reluctant to add dependencies,
  preferring to copy/paste Lua code instead,
  often reinventing the wheel in a suboptimal manner.

Other more modern approaches rely on plugin authors
providing this information in their source repositories.
We have a detailed article explaining why we chose a different approach [here](https://github.com/nvim-neorocks/lux.nvim/wiki/What-about-packspec-(pkg.json)%3F).

With lux.nvim, installing a plugin is as simple as entering the command:

```
:Lux add foo.nvim
```

Welcome to a new era of Neovim plugin management - where simplicity meets efficiency!

### :milky_way: Philosophy

lux.nvim itself is designed based on the UNIX philosophy:
Do one thing well.

It doesn't dictate how you as a user should configure your plugins.
But there's an optional module for those seeking
additional configuration capabilities: [`lux-config.nvim`](https://github.com/nvim-neorocks/lux-config.nvim).

We have packaged [many Neovim plugins and tree-sitter parsers](https://luarocks.org/modules/neorocks)
for luarocks, and an increasing number of plugin authors
[have been publishing themselves](https://luarocks.org/labels/neovim?non_root=on).
Additionally, [`lux-git.nvim`](https://github.com/nvim-neorocks/lux-git.nvim)
ensures you're covered even when a plugin isn't directly available on LuaRocks.

### :deciduous_tree: Enhanced tree-sitter support

> [!WARNING]
>
> **We are not affiliated with the nvim-treesitter maintainers.
> If you are facing issues with tree-sitter support in lux.nvim,
> please don't bug them.**

We're revolutionizing the way Neovim users and plugin developers
interact with tree-sitter parsers.
With the introduction of the [Neovim User Rocks Repository (NURR)](https://github.com/nvim-neorocks/nurr),
we have automated the packaging and publishing of many plugins and curated[^2] tree-sitter parsers
for luarocks, ensuring a seamless and efficient user experience.

[^2]: We only upload parsers which we can install in the NURR CI
      (tested on Linux).

When installing, lux.nvim will also search our [lux-binaries (dev)](https://nvim-neorocks.github.io/lux-binaries-dev/)
server, which means you don't even need to compile any parsers
on your machine.

#### Effortless installation for users

If you need a tree-sitter parser for syntax highlighting or other features,
you can easily install them with lux.nvim: `:Lux add tree-sitter-<lang>`.

They come bundled with queries, so once installed,
all you need to do is run `vim.treesitter.start()` to enable syntax highlighting[^3].

[^3]: You can put this in a `ftplugin/<filetype>.lua`, for example.

Or, you can use our [`lux-treesitter.nvim`](https://github.com/nvim-neorocks/lux-treesitter.nvim)
module, which can automatically install parsers and enable syntax highlighting for you.

> [!TIP]
>
> Bonus: With lux.nvim, you can [**pin and roll back each tree-sitter parser individually!**](https://mrcjkb.dev/posts/2024-07-28-tree-sitter.html)

<!-- Or, if you want something that comes with lots of tree-sitter parsers and -->
<!-- automatically configures nvim-treesitter for you, -->
<!-- check out our [`lux-treesiter.nvim` module](https://github.com/nvim-neorocks/lux-treesitter.nvim). -->

#### Simplifying dependencies

For plugin developers, specifying a tree-sitter parser as a dependency
is now as straightforward as including it in their project's rockspec[^4].
This eliminates the need for manual parser management and ensures that
dependencies are automatically resolved and installed.

[^4]: [example](https://luarocks.org/modules/MrcJkb/neotest-haskell).

Example rockspec dependency specification:

```lua
dependencies = {
  "neotest",
  "tree-sitter-haskell"
}
```

## :pencil: Requirements

- An up-to-date `Neovim >= 0.10` installation.
- `wget` or `curl` (if running on a UNIX system) - required for the remote `:source` command to work.

## :inbox_tray: Installation

### :zap: Installation script (recommended)

The days of bootstrapping and editing your configuration are over.
`lux.nvim` can be installed directly through an interactive installer within Neovim.

We suggest starting nvim without loading RC files, such that already installed plugins do not interfere
with the installer:

```sh
nvim -u NORC -c "source https://raw.githubusercontent.com/nvim-neorocks/lux.nvim/master/installer.lua"
```

> [!IMPORTANT]
>
> For security reasons, we recommend that you read `:help :source`
> and the installer code before running it so you know exactly what it does.

### :rocket: Bootstrapping Script

For those who want `lux.nvim` to automatically install itself whenever it isn't installed
one may use the bootstrapping script. Place the following script into your `init.lua`:

<details>
<summary>Lua Script</summary>

```lua
-- TODO
```

</details>

Upon running `nvim` the bootstrapping script should engage!

> [!NOTE]
> If you would like to break down this snippet into separate files, *make sure*
> that the runtimepath and configuration snippet (the `do .. end` block) executes
> *before* the actual bootstrapping logic. You will get errors if you do it the other
> way around!

### :hammer: Manual installation

For manual installation, see [this tutorial](https://github.com/nvim-neorocks/lux.nvim/wiki/Installing-lux.nvim-manually,-without-the-installation-script).

## :books: Usage

See also [`:h lux-nvim`](./doc/lux.txt).

### Editing `lux.toml`

The `:Lux edit` command opens the `lux.toml` file for manual editing.
Make sure to run `:Lux sync` when you are done.

> [!TIP]
>
> #### Should I lazy load plugins?
>
> Making sure a plugin doesn't unnecessarily impact startup time
> [should be the responsibility of plugin authors, not users](https://github.com/nvim-neorocks/nvim-best-practices?tab=readme-ov-file#sleeping_bed-lazy-loading).
> As is the case with dependencies, a plugin's functionality may evolve over
> time, potentially leading to breakage if it's the user who has
> to worry about lazy loading.
>
> A plugin that implements its own lazy initialization properly
> will likely have less overhead than the mechanisms used by a
> plugin manager or user to load that plugin lazily.
>
> If you find a plugin that takes too long to load,
> or worse, forces you to load it manually at startup with a
> call to a heavy `setup` function,
> consider opening an issue on the plugin's issue tracker.

## :calendar: User events

For `:h User` events that lux.nvim will trigger, see `:h lux.user-event`.

## :package: Extending `lux.nvim`

This plugin provides a Lua API for extensibility.
See [`:h lux-api`](./doc/lux.txt) for details.

Following are some examples:

- [`lux-git.nvim`](https://github.com/nvim-neorocks/lux-git.nvim):
  Adds the ability to install plugins from git.
- [`lux-config.nvim`](https://github.com/nvim-neorocks/lux-config.nvim):
  Adds an API for safely loading plugin configurations.
- [`lux-lazy.nvim`](https://github.com/nvim-neorocks/lux-lazy.nvim):
  Adds lazy-loading abstractions and integrates with lux-config.nvim.
- [`lux-dev.nvim`](https://github.com/nvim-neorocks/lux-dev.nvim):
  Adds an API for developing and testing luarocks plugins locally.
- [`lux-treesitter.nvim`](https://github.com/nvim-neorocks/lux-treesitter.nvim)
  Automatic highlighting and installation of tree-sitter parsers.
- And [more...](https://github.com/topics/lux-nvim)


To extend `lux.nvim`, simply install a module with `:Lux add`,
and you're good to go!

## :stethoscope: Troubleshooting

The `:Lux log` command opens a log file for the current session,
which contains any errors that may have occured when running `lux.nvim`.

## :link: projects related to neovim and luarocks

- [luarocks-tag-release](https://github.com/nvim-neorocks/luarocks-tag-release):
  A GitHub action that automates publishing to luarocks.org
- [NURR](https://github.com/nvim-neorocks/nurr):
  A repository that publishes Neovim plugins and tree-sitter parsers
  to luarocks.org
- [luarocks.nvim](https://github.com/vhyrro/luarocks.nvim):
  Adds basic support for installing lua rocks to [lazy.nvim](https://github.com/folke/lazy.nvim)


## :link: Other neovim plugin managers

- [lazy.nvim](https://github.com/folke/lazy.nvim): started luarocks support in
  version [11.X](https://lazy.folke.io/news#11x)
- [mini.deps](https://github.com/echasnovski/mini.deps)
- [paq-nvim](https://github.com/savq/paq-nvim)
- [pckr](https://github.com/lewis6991/pckr.nvim)
- [vim-plug](https://github.com/junegunn/vim-plug)

## :book: License

`lux.nvim` is licensed under [GPLv3](./LICENSE).

## :green_heart: Contributing

Contributions are more than welcome!
See [CONTRIBUTING.md](./CONTRIBUTING.md) for a guide.
