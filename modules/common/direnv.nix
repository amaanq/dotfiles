{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  home-manager.sharedModules = [
    {
      programs.direnv = enabled {
        enableNushellIntegration = true;
        nix-direnv.enable = true;
        silent = true;
      };
    }
  ];
}
