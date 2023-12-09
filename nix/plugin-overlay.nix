{
  name,
  self,
}: final: prev: let
  lib = final.lib;
  rocks-nvim-luaPackage-override = luaself: luaprev: {
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
            src =
              fetchzip {
                url = "https://github.com/j-hui/fidget.nvim/archive/300018af4
abd00610a345e382ca1f4b7ba420f77.zip";
                sha256 = "0bwjcqkb735wqnzc8rngvpq1b2rxgc7m0arjypvnvzsxw6wd1f61";
              };
            propagatedBuildInputs = [lua];
          }) {};

    rocks-nvim = luaself.callPackage ({
      luaOlder,
      buildLuarocksPackage,
      lua,
      toml,
      toml-edit,
      fidget-nvim,
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
      viAlias = true;
      vimAlias = true;
      plugins = with final.vimPlugins; [
        rocks-nvim
      ];
    };
    runtimeDeps = with final; [
      lua5_1
      luarocks
    ];
    customRC = builtins.readFile ./init.lua;
  in
    final.wrapNeovimUnstable final.neovim-nightly (neovimConfig
      // {
        wrapperArgs =
          lib.escapeShellArgs neovimConfig.wrapperArgs
          + " "
          + ''--add-flags -u --add-flags "${final.writeText "init.lua" customRC}"''
          + " "
          + ''--set NVIM_APPNAME "nvimrocks"''
          + " "
          # XXX: Luarocks packages need to be added manaully,
          # using LUA_PATH and LUA_CPATH.
          # It looks like buildNeovimPlugin is broken?
          + ''--suffix LUA_CPATH ";" "${
              lib.concatMapStringsSep ";" lua51Packages.getLuaCPath
              (with lua51Packages; [
                toml
                toml-edit
                fidget-nvim
                fzy
              ])
            }"''
          + " "
          + ''--suffix LUA_PATH ";" "${
              lib.concatMapStringsSep ";" lua51Packages.getLuaPath
              (with lua51Packages; [
                fidget-nvim
                fzy
              ])
            }"''
          + " "
          + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
      });
}
