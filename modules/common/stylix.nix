{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    disabled
    enabled
    mkIf
    ;
in
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix = mkIf config.isDesktop (enabled {
    autoEnable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    opacity = {
      terminal = 0.9;
      popups = 0.8;
    };
    targets = {
      plymouth = disabled;
      grub = disabled;
    };
  });

  home-manager.sharedModules = mkIf config.isDesktop [
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
        };
      };
    }
  ];
}
