{
  description = "Definitely not a Neovim and Luarocks breed";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    neorocks.url = "github:nvim-neorocks/neorocks";

    gen-luarc = {
      url = "github:mrcjkb/nix-gen-luarc-json";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cats-doc.url = "github:mrcjkb/cats-doc";

    flake-parts.url = "github:hercules-ci/flake-parts";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    gen-luarc,
    flake-parts,
    pre-commit-hooks,
    ...
  }: let
    name = "rocks.nvim";

    plugin-overlay = import ./nix/plugin-overlay.nix {
      inherit name self;
    };
    test-overlay = import ./nix/test-overlay.nix {
      inherit self inputs;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neorocks.overlays.default
            gen-luarc.overlays.default
            plugin-overlay
            test-overlay
          ];
        };

        mk-luarc = nvim:
          pkgs.mk-luarc {
            inherit nvim;
            plugins = with pkgs.lua51Packages; [
              toml-edit
              fidget-nvim
              fzy
              nvim-nio
            ];
            disabled-diagnostics = [
              # caused by a nio luaCATS bug
              "redundant-return-value"
              # we use @package to prevent lemmy-help from generating vimdoc
              "invisible"
            ];
          };

        luarc-nightly = mk-luarc pkgs.neovim-nightly;
        luarc-stable = mk-luarc pkgs.neovim-unwrapped;

        mk-type-check = luarc:
          pre-commit-hooks.lib.${system}.run {
            src = self;
            hooks = {
              lua-ls = {
                enable = true;
                settings.configuration = luarc;
              };
            };
          };

        type-check-nightly = mk-type-check luarc-nightly;
        type-check-stable = mk-type-check luarc-stable;

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            stylua.enable = true;
            luacheck.enable = true;
            editorconfig-checker.enable = true;
          };
        };

        devShell = pkgs.integration-nightly.overrideAttrs (oa: {
          name = "rocks.nvim devShell";
          shellHook = ''
            ${pre-commit-check.shellHook}
            ln -fs ${pkgs.luarc-to-json luarc-nightly} .luarc.json
            export GIT2_DIR=${pkgs.libgit2.lib}
          '';
          buildInputs =
            self.checks.${system}.pre-commit-check.enabledPackages
            ++ (with pkgs; [
              lua-language-server
              # For tree-sitter parsers that need sources
              # to be generated
              gcc
              tree-sitter
              docgen
            ])
            ++ oa.buildInputs
            ++ oa.propagatedBuildInputs;
          doCheck = false;
        });
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = rocks-nvim;
          inherit (pkgs.luajitPackages) rocks-nvim;
          inherit
            (pkgs)
            neovim-with-rocks
            docgen
            ;
        };

        # TODO: add integration-stable when ready
        checks = {
          inherit
            pre-commit-check
            type-check-stable
            type-check-nightly
            ;
          inherit
            (pkgs)
            integration-nightly
            ;
        };
      };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}
