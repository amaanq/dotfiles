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
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix = enabled {
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
  };
}
