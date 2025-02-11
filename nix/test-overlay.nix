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
            luarocks
            toml-edit
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
in {
  integration-stable = mkNeorocksTest "integration-stable" final.neovim;
  integration-nightly = mkNeorocksTest "integration-nightly" final.neovim-nightly;
}
