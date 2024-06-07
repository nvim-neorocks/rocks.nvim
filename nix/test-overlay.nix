{self}: final: prev: let
  mkNeorocksTest = name: nvim:
    with final;
      neorocksTest {
        inherit name;
        pname = "rocks.nvim";
        src = self;
        neovim = nvim;
        luaPackages = ps:
          with ps; [
            luarocks-rock
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
        '';
      };

  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = with final; [
      lemmy-help
    ];
    text = ''
      mkdir -p doc
      lemmy-help lua/rocks/{commands,config/init,api/{init,hooks},log}.lua > doc/rocks.txt
    '';
  };
in {
  integration-stable = mkNeorocksTest "integration-stable" final.neovim;
  integration-nightly = mkNeorocksTest "integration-nightly" final.neovim-nightly;
  inherit docgen;
}
