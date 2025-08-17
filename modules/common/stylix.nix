{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    disabled
    enabled
    ;
in
{
  home-manager.sharedModules = [
    inputs.stylix.homeModules.stylix
    {
      stylix = enabled {
        autoEnable = true;
        cursor = {
          name = "rose-pine-hyprcursor";
          package = pkgs.rose-pine-hyprcursor;
          size = 24;
        };
        targets = {
          gtk = disabled;
          helix = disabled;
          hyprlock = disabled;
          kitty = disabled;
          ghostty = disabled;
          zen-browser.profileNames = [ "default" ];
        };
      };
    }
  ];
}
