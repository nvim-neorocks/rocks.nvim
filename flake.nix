{
  description = "Definitely not a Neovim and Luarocks breed";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    neorocks.url = "github:nvim-neorocks/neorocks";

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
    flake-parts,
    pre-commit-hooks,
    ...
  }: let
    name = "rocks.nvim";

    plugin-overlay = import ./nix/plugin-overlay.nix {
      inherit name self;
    };
    test-overlay = import ./nix/test-overlay.nix {
      inherit self;
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
            plugin-overlay
            neorocks.overlays.default
            test-overlay
          ];
        };

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            # FIXME: Uncomment when stylua has a --respect-ignores flag
            # stylua.enable = true;
            luacheck.enable = true;
            editorconfig-checker.enable = true;
          };
        };

        devShell = pkgs.mkShell {
          name = "rocks.nvim devShell";
          inherit (pre-commit-check) shellHook;
          buildInputs = with pre-commit-hooks.packages.${system};
            [
              alejandra
              lua-language-server
              stylua
              luacheck
              editorconfig-checker
            ]
            ++ (with pkgs; [
              luarocks
            ]);
        };
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = rocks-nvim;
          inherit (pkgs.vimPlugins) rocks-nvim;
          inherit (pkgs) neovim-with-rocks;
        };

        # TODO: add integration-stable when ready
        checks = {
          lints = pre-commit-check;
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
