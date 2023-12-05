{
  name,
  self,
}: final: prev: let
  lib = final.lib;
  rocks-nvim-luaPackage-override = luaself: luaprev: {
    rocks-nvim = luaself.callPackage ({
      luaOlder,
      buildLuarocksPackage,
      lua,
      toml,
      toml-edit,
      nui-nvim,
    }:
      buildLuarocksPackage {
        pname = name;
        version = "scm-1";
        knownRockspec = "${self}/rocks.nvim-scm-1.rockspec";
        src = self;
        disabled = luaOlder "5.1";
        propagatedBuildInputs = [toml toml-edit nui-nvim];
      }) {};
  };
  lua5_1 = prev.lua5_1.override {
    packageOverrides = rocks-nvim-luaPackage-override;
  };
  lua51Packages = final.lua5_1.pkgs;
in {
  inherit lua5_1 lua51Packages;

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
          + ''--suffix LUA_CPATH ";" "${
              lib.concatMapStringsSep ";" lua51Packages.getLuaCPath
              (with lua51Packages; [
                toml
                toml-edit
              ])
            }"''
          + " "
          + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
      });
}
