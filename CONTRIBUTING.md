# Contributing guide

Contributions are more than welcome!

## Commit messages / PR title

Please ensure your pull request title conforms to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## CI

Our CI checks are run using [`nix`](https://nixos.org/download.html#download-nix).

## Development

### Dev environment

We use the following tools:

#### Formatting

- [`.editorconfig`](https://editorconfig.org/) (with [`editorconfig-checker`](https://github.com/editorconfig-checker/editorconfig-checker))
- [`stylua`](https://github.com/JohnnyMorganz/StyLua) [Lua]
- [`alejandra`](https://github.com/kamadorueda/alejandra) [Nix]

#### Linting

- [`luacheck`](https://github.com/mpeterv/luacheck)

#### Static type checking

- [`lua-language-server`](https://github.com/LuaLS/lua-language-server/wiki/Diagnosis-Report#create-a-report)

### Nix devShell

- Requires [flakes](https://nixos.wiki/wiki/Flakes) to be enabled.

We provide a `flake.nix` that can bootstrap all of the above development tools.

To enter a development shell:

```console
nix develop
```

To apply formatting, while in a devShell, run

```console
pre-commit run --all
```

If you use [`direnv`](https://direnv.net/),
just run `direnv allow` and you will be dropped in this devShell.

### Running tests

We use [`busted`](https://lunarmodules.github.io/busted/) for testing,
but with Neovim as the Lua interpreter.

The easiest way to run tests is with Nix (see below).

If you do not use Nix, you can also run the test suite using `luarocks test`.
For more information on how to set up Neovim as a Lua interpreter, see

- The [neorocks tutorial](https://github.com/nvim-neorocks/neorocks#without-neolua).

Or

- [`nlua`](https://github.com/mfussenegger/nlua).

> [!NOTE]
>
> The Nix devShell sets up `luarocks test` to use Neovim as the interpreter.

### Running tests and checks with Nix

If you just want to run all checks that are available, run:

```console
nix flake check -L --option sandbox false
```

To run tests locally, using Nix:

```console
nix build .#checks.<your-system>.integration-nightly -L --option sandbox false
```

For example:

```console
nix build .#checks.x86_64-linux.integration-nightly -L --option sandbox false
```

For formatting and linting:

```console
nix build .#checks.<your-system>.pre-commit-check -L
```

For static type checking:

```console
nix build .#checks.<your-system>.type-check-nightly -L
```

### Manual testing

If you want to test your contributions to `rocks.nvim` manually,
we recommend you set [`NVIM_APPNAME`](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)
to something other than `nvim`, so that your test environment
doesn't interfere with your regular Neovim installation.

We also provide a Nix flake output that you can use to test-drive `rocks.nvim`:

```console
nix run .#neovim-with-rocks
```

It sets `NVIM_APPNAME` to `nvimrocks`.
