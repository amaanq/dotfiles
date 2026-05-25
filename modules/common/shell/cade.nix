{ lib, ... }:
let
  inherit (lib) enabled;
in
{
  programs.cade = enabled {
    enableBashIntegration = false;
    enableZshIntegration = false;
    enableFishIntegration = false;
  };
}
