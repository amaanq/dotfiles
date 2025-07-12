{ lib, pkgs, ... }:
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

  environment.systemPackages = [
    pkgs.go
  ];

  home-manager.sharedModules = [
    {
      programs.neovim = enabled {
        defaultEditor = true;
      };
    }
  ];
}
