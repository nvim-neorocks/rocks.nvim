{
  name,
  self,
}: final: prev: let
  lib = final.lib;
  rocks-nvim-luaPackage-override = luaself: luaprev: {
    toml-edit =
      (luaself.callPackage ({
        buildLuarocksPackage,
        fetchzip,
        fetchurl,
        lua,
        luaOlder,
        luarocks-build-rust-mlua,
      }:
        buildLuarocksPackage {
          pname = "toml-edit";
          version = "0.3.3-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/toml-edit-0.3.3-1.rockspec";
              sha256 = "024s0x7g3i8014ay6ssax8zdsfda8n5dl354phks0cchjl7jsiqw";
            })
            .outPath;
          src = fetchzip {
            url = "https://github.com/vhyrro/toml-edit.lua/archive/v0.3.3.zip";
            sha256 = "10nvn1snagrqkqx48r16nzbgyhcg020lprw2qgpwbyl7ycp4ppmc";
          };

          disabled = luaOlder "5.1";
          propagatedBuildInputs = [lua];
        }) {})
      .overrideAttrs (oa: {
        cargoDeps = final.rustPlatform.fetchCargoTarball {
          src = oa.src;
          hash = "sha256-Fmd69FGHqITotrXNTfuuWGI+d+i2zq9hwjQMjF+isE4=";
        };
        nativeBuildInputs = with final; [cargo rustPlatform.cargoSetupHook] ++ oa.nativeBuildInputs;
      });

    nvim-nio =
      # TODO: Replace with nixpkgs package when available
      luaself.callPackage ({
        buildLuarocksPackage,
        fetchurl,
        fetchzip,
        lua,
        luaOlder,
      }:
        buildLuarocksPackage {
          pname = "nvim-nio";
          version = "1.9.0-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/nvim-nio-1.9.0-1.rockspec";
              sha256 = "0hwjkz0pjd8dfc4l7wk04ddm8qzrv5m15gskhz9gllb4frnk6hik";
            })
            .outPath;
          src = fetchzip {
            url = "https://github.com/nvim-neotest/nvim-nio/archive/v1.9.0.zip";
            sha256 = "0y3afl42z41ymksk29al5knasmm9wmqzby860x8zj0i0mfb1q5k5";
          };

          disabled = luaOlder "5.1";
          propagatedBuildInputs = [lua];

          meta = {
            homepage = "https://github.com/nvim-neotest/nvim-nio";
            description = "A library for asynchronous IO in Neovim";
            license.fullName = "MIT";
          };
        }) {};

    fidget-nvim =
      # TODO: Replace with nixpkgs package when available
      luaself.callPackage ({
        buildLuarocksPackage,
        fetchurl,
        fetchzip,
        lua,
        luaOlder,
      }:
        buildLuarocksPackage {
          pname = "fidget.nvim";
          version = "1.1.0-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/fidget.nvim-1.1.0-1.rockspec";
              sha256 = "0pgjbsqp6bs9kwi0qphihwhl47j1lzdgg3xfa6msikrcf8d7j0hf";
            })
            .outPath;
          src = fetchzip {
            url = "https://github.com/j-hui/fidget.nvim/archive/300018af4abd00610a345e382ca1f4b7ba420f77.zip";
            sha256 = "0bwjcqkb735wqnzc8rngvpq1b2rxgc7m0arjypvnvzsxw6wd1f61";
          };

          disabled = luaOlder "5.1";
          propagatedBuildInputs = [lua];

          meta = {
            homepage = "https://github.com/j-hui/fidget.nvim";
            description = "Extensible UI for Neovim notifications and LSP progress messages.";
            license.fullName = "MIT";
          };
        }) {};

    rocks-nvim = luaself.callPackage ({
      luaOlder,
      buildLuarocksPackage,
      lua,
      luarocks,
      toml-edit,
      fidget-nvim,
      nvim-nio,
      fzy,
    }:
      buildLuarocksPackage {
        pname = name;
        version = "scm-1";
        knownRockspec = "${self}/rocks.nvim-scm-1.rockspec";
        src = self;
        disabled = luaOlder "5.1";
        propagatedBuildInputs = [
          luarocks
          toml-edit
          fidget-nvim
          nvim-nio
          fzy
        ];
      }) {};
  };
  lua5_1 = prev.lua5_1.override {
    packageOverrides = rocks-nvim-luaPackage-override;
  };
  lua51Packages = final.lua5_1.pkgs;
in {
  inherit
    lua5_1
    lua51Packages
    ;

  vimPlugins =
    prev.vimPlugins
    // {
      rocks-nvim = final.neovimUtils.buildNeovimPlugin {
        pname = name;
        version = "dev";
        src = self;
      };
    };

  neovim-with-rocks = let
    neovimConfig = final.neovimUtils.makeNeovimConfig {
      withPython3 = true;
      viAlias = false;
      vimAlias = false;
      plugins = [
        final.vimPlugins.rocks-git-nvim
      ];
    };
    rocks = lua51Packages.rocks-nvim;
  in
    final.wrapNeovimUnstable final.neovim-nightly (neovimConfig
      // {
        luaRcContent =
          /*
          lua
          */
          ''
            -- Copied from installer.lua
            local rocks_config = {
                rocks_path = vim.fn.stdpath("data") .. "/rocks",
                luarocks_binary = "${final.luarocks}/bin/luarocks",
            }

            vim.g.rocks_nvim = rocks_config

            local luarocks_path = {
                vim.fs.joinpath("${rocks}", "share", "lua", "5.1", "?.lua"),
                vim.fs.joinpath("${rocks}", "share", "lua", "5.1", "?", "init.lua"),
                vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),
                vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
            }
            package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

            local luarocks_cpath = {
                vim.fs.joinpath("${rocks}", "lib", "lua", "5.1", "?.so"),
                vim.fs.joinpath("${rocks}", "lib64", "lua", "5.1", "?.so"),
                vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.so"),
                vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.so"),
            }
            package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

            vim.opt.runtimepath:append(vim.fs.joinpath("${rocks}", "rocks.nvim-scm-1-rocks", "rocks.nvim", "*"))
          '';
        wrapRc = true;
        wrapperArgs =
          lib.escapeShellArgs neovimConfig.wrapperArgs
          + " "
          + ''--set NVIM_APPNAME "nvimrocks"'';
      });
}
