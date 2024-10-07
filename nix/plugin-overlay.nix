{
  name,
  self,
}: final: prev: let
  lib = final.lib;
  luaPackage-override = luaself: luaprev: {
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
          version = "0.4.1-1";
          knownRockspec =
            (fetchurl {
              url = "mirror://luarocks/toml-edit-0.4.1-1.rockspec";
              sha256 = "180zdqrzffr7jr9xls895gj5hrx6pfs98rlxwzg71382jy1n79qi";
            })
            .outPath;
          src = fetchzip {
            url = "https://github.com/vhyrro/toml-edit.lua/archive/v0.4.1.zip";
            sha256 = "1322p490p6yza3lczfzmwf5nkfj4ra6m9g6hvr2qgay405wnpgy7";
          };

          disabled = luaOlder "5.1";
          propagatedBuildInputs = [lua luarocks-build-rust-mlua];
        }) {})
      .overrideAttrs (oa: {
        cargoDeps = final.rustPlatform.fetchCargoTarball {
          src = oa.src;
          hash = "sha256-PLihirhJshcUQI3L1eTcnQiZvocDl29eQHhdBwJQRU8=";
        };
        nativeBuildInputs = with final; [cargo rustPlatform.cargoSetupHook] ++ oa.nativeBuildInputs;
      });

    rtp-nvim = luaself.callPackage ({
      buildLuarocksPackage,
      fetchzip,
      fetchurl,
      lua,
      luaOlder,
    }:
      buildLuarocksPackage {
        pname = "rtp.nvim";
        version = "1.0.0-1";
        knownRockspec =
          (fetchurl {
            url = "mirror://luarocks/rtp.nvim-1.0.0-1.rockspec";
            sha256 = "0ddlwhk62g3yx1ysddsmlggfqv0hj7dljgczfwij1ijbz7qyp3hy";
          })
          .outPath;
        src = fetchzip {
          url = "https://github.com/nvim-neorocks/rtp.nvim/archive/v1.0.0.zip";
          sha256 = "1kx7qzdz8rpwsjcp63wwn619nrkxn6xd0nr5pfm3g0z4072nnpzn";
        };

        disabled = luaOlder "5.1";
        propagatedBuildInputs = [lua];
      }) {};

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
      rtp-nvim,
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
          rtp-nvim
        ];
      }) {};
  };
  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackage-override;
  };
  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;
  luajit = prev.luajit.override {
    packageOverrides = luaPackage-override;
  };
  luajitPackages = prev.luajitPackages // final.luajit.pkgs;
in {
  inherit
    lua5_1
    lua51Packages
    luajit
    luajitPackages
    ;

  vimPlugins =
    prev.vimPlugins
    // {
      rocks-nvim = final.neovimUtils.buildNeovimPlugin {
        luaAttr = luajitPackages.rocks-nvim;
      };
    };

  neovim-with-rocks = let
    neovimConfig = final.neovimUtils.makeNeovimConfig {
      withPython3 = true;
      viAlias = false;
      vimAlias = false;
      plugins = [
        final.vimPlugins.rocks-nvim
      ];
    };
    rocks = luajitPackages.rocks-nvim;
  in
    (final.wrapNeovimUnstable final.neovim-nightly (neovimConfig
      // {
        luaRcContent =
          /*
          lua
          */
          ''
            -- Copied from installer.lua
            local rocks_config = {
                rocks_path = vim.fn.stdpath("data") .. "/rocks",
                luarocks_binary = "${final.luajitPackages.luarocks}/bin/luarocks",
            }

            vim.g.rocks_nvim = rocks_config

            local luarocks_path = {
                vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),
                vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
            }
            package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

            local luarocks_cpath = {
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
      }))
    .overrideAttrs (oa: {
      nativeBuildInputs =
        oa.nativeBuildInputs
        ++ [
          final.luajit.pkgs.wrapLua
          # rocks
        ];
      # postFixup = ''
      #   wrapLuaPrograms
      # '';
    });
}
