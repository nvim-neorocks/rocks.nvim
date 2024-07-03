{
  self,
  inputs,
}: final: prev: let
  mkNeorocksTest = name: nvim:
    with final;
      neorocksTest {
        inherit name;
        pname = "rocks.nvim";
        src = self;
        neovim = nvim;
        luaPackages = ps:
          with ps; [
            final.lua51Packages.luarocks-rock
            toml-edit
            toml
            fidget-nvim
            fzy
            nvim-nio
            rtp-nvim
          ];

        extraPackages = [
          wget
          git
          cacert
        ];

        preCheck = ''
          # Neovim expects to be able to create log files, etc.
          export HOME=$(realpath .)
          export GIT2_DIR=${final.libgit2.lib}
        '';
      };

  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = [
      inputs.cats-doc.packages.${final.system}.default
    ];
    text = ''
      mkdir -p doc
      lemmy-help lua/rocks/{init,commands,config/init,api/{init,hooks},log}.lua > doc/rocks.txt
    '';
  };
in {
  integration-stable = mkNeorocksTest "integration-stable" final.neovim;
  integration-nightly = mkNeorocksTest "integration-nightly" final.neovim-nightly;
  inherit docgen;
}
