{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    disabled
    enabled
    optionalAttrs
    ;
in
{
  stylix = enabled {
    autoEnable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    opacity = {
      terminal = 0.9;
      popups = 0.8;
    };
    targets = optionalAttrs config.isLinux {
      plymouth = disabled;
      grub = disabled;
    };
  };

  home-manager.sharedModules = [
    {
      stylix = enabled {
        autoEnable = true;
        targets = {
          gtk = disabled;
          helix = disabled;
          kitty = disabled;
          ghostty = disabled;
        };
      };
    }
  ];
}
