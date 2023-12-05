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
          nui-nvim
          fzy
        ];
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
  in
    final.wrapNeovimUnstable final.neovim-nightly (neovimConfig
      // {
        wrapperArgs =
          lib.escapeShellArgs neovimConfig.wrapperArgs
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
                nui-nvim
                fzy
              ])
            }"''
          + " "
          + ''--suffix LUA_PATH ";" "${
              lib.concatMapStringsSep ";" lua51Packages.getLuaPath
              (with lua51Packages; [
                fzy
              ])
            }"''
          + " "
          + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
        wrapRc = false;
      });
}
