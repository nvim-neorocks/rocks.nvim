{fetchurl}: [
  {
    url = "https://github.com/nvim-lua/plenary.nvim/info/refs?service=git-upload-pack";
    file = fetchurl {
      url = "https://github.com/nvim-lua/plenary.nvim/info/refs?service=git-upload-pack";
      hash = "sha256-cnzxKmuEOlUoC+S+CUVpsUDQQ2NGfH1xLPwdfbjPV4g=";
    };
    status_code = 200;
    headers = {
      "content-type" = "application/x-git-upload-pack-advertisement";
    };
  }
  {
    url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
    file = fetchurl {
      url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
      hash = "sha256-LceYA8EEk24i0D5ameQU6iKOz/SGP26m61KcY5bUTXg=";
    };
    status_code = 200;
    headers = {"content-type" = "application/x-git-upload-pack-result";};
  }
  {
    url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
    file = fetchurl {
      url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
      hash = "sha256-nhtM9b/cyj6rP5j6eFza52ycxV84Xd6pPF6JxCDBdqk=";
    };
    status_code = 200;
    headers = {"content-type" = "application/x-git-upload-pack-result";};
  }
  {
    url = "https://github.com/nvim-lua/plenary.nvim/info/refs?service=git-upload-pack";
    file = fetchurl {
      url = "https://github.com/nvim-lua/plenary.nvim/info/refs?service=git-upload-pack";
      hash = "sha256-cnzxKmuEOlUoC+S+CUVpsUDQQ2NGfH1xLPwdfbjPV4g=";
    };
    status_code = 200;
    headers = {
      "content-type" = "application/x-git-upload-pack-advertisement";
    };
  }
  {
    url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
    file = fetchurl {
      url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
      hash = "sha256-LceYA8EEk24i0D5ameQU6iKOz/SGP26m61KcY5bUTXg=";
    };
    status_code = 200;
    headers = {"content-type" = "application/x-git-upload-pack-result";};
  }
  {
    url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
    file = fetchurl {
      url = "https://github.com/nvim-lua/plenary.nvim/git-upload-pack";
      hash = "sha256-6LixX1Wmp12pn8mcgHE5Oe4z1tbS/J1gZ6iXzoH7cjE=";
    };
    status_code = 200;
    headers = {"content-type" = "application/x-git-upload-pack-result";};
  }
]
