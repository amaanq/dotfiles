{ config, lib, ... }:
let
  inherit (lib) enabled mkIf;
in
{
  config = mkIf config.isDesktop {
    programs.cade = enabled {
      enableBashIntegration = false;
      enableZshIntegration = false;
      enableFishIntegration = false;
    };
  };
}
