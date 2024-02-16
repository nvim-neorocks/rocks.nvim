{
  name,
  self,
}: final: prev: let
  lib = final.lib;
  rocks-nvim-luaPackage-override = luaself: luaprev: {
    toml-edit =
      (luaself.callPackage ({
        buildLuarocksPackage,
        fetchgit,
        fetchurl,
        lua,
        luaOlder,
        luarocks-build-rust-mlua,
      }:
        buildLuarocksPackage {
          pname = "toml-edit";
          version = "0.1.5-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/toml-edit-0.1.5-1.rockspec";
              sha256 = "1xgjh8x44kn24vc29si811zq2a7pr24zqj4w07pys5k6ccnv26qz";
            })
            .outPath;
          src = fetchgit (removeAttrs (builtins.fromJSON ''            {
              "url": "https://github.com/vhyrro/toml-edit.lua",
              "rev": "34f072d8ff054b3124d9d2efc0263028d7425525",
              "date": "2023-12-29T15:53:36+01:00",
              "path": "/nix/store/z1gn59hz9ypk3icn3gmafaa19nzx7a1v-toml-edit.lua",
              "sha256": "0jzzp4sd48haq1kmh2k85gkygfq39i10kvgjyqffcrv3frdihxvx",
              "hash": "sha256-fXcYW3ZjZ+Yc9vLtCUJMA7vn5ytoClhnwAoi0jS5/0s=",
              "fetchLFS": false,
              "fetchSubmodules": true,
              "deepClone": false,
              "leaveDotGit": false
            }
          '') ["date" "path" "sha256"]);

          propagatedBuildInputs = [lua luarocks-build-rust-mlua];
        }) {})
      .overrideAttrs (oa: {
        cargoDeps = final.rustPlatform.fetchCargoTarball {
          src = oa.src;
          hash = "sha256-gvUqkLOa0WvAK4GcTkufr0lC2BOs2FQ2bgFpB0qa47k=";
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
          version = "1.2.0-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/nvim-nio-1.2.0-1.rockspec";
              sha256 = "0a62iv1lyx8ldrdbip6az0ixm8dmpcai3k8j5jsf49cr4zjpcjzk";
            })
            .outPath;
          src = fetchzip {
            url = "https://github.com/nvim-neotest/nvim-nio/archive/11864149f47e0c7a38c4dadbcea8fc17c968556e.zip";
            sha256 = "141py3csgbijpqhscgmsbnkg4lbx7ma7nwpj0akfc7v37c143dq3";
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
      toml,
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
          toml
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
    };
    runtimeDeps = with final; [
      lua5_1
      luarocks
    ];
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
          + ''--set NVIM_APPNAME "nvimrocks"''
          + " "
          + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
      });
}
