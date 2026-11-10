{
  core = builtins.fetchGit {
    url = "https://github.com/ekala-project/corepkgs.git";
    rev = "f61b97b7340aa90aa47731b8655f67f80a2062dc";
  };

  lib = builtins.fetchGit {
    url = "https://github.com/jonringer/nix-lib.git";
    rev = "2c14377c3f3825e2cd5ebf43858ec4aaac5bffde";
  };
}
