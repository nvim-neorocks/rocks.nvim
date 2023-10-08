{
  name,
  self,
}: final: prev: {
  vimPlugins.rocks-nvim = final.pkgs.vimUtils.buildVimPlugin {
    inherit name;
    src = self;
  };
}
