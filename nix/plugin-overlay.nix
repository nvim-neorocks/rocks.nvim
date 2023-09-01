{
  name,
  self,
}: final: prev: {
  vimPlugins.rocks-nvim = final.pkgs.vimUtils.buildVimPluginFrom2Nix {
    inherit name;
    src = self;
  };
}
