{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.shellAliases = {
    nv = "nvim";
    vi = "nvim";
  };

  home-manager.sharedModules = [
    {
      programs.neovim = enabled {
        defaultEditor = true;
      };
    }
  ];
}
