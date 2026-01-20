{
  config,
  lib,
  pkgs,
  qtengine,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.kdePackages.breeze
    pkgs.kdePackages.breeze.qt5
    pkgs.kdePackages.breeze-icons
    qtengine.packages.${pkgs.system}.default
  ];

  programs.qtengine = enabled {
    config = {
      theme = {
        colorScheme = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
        iconTheme = "breeze-dark";
        style = "breeze";

        font = {
          family = "Noto Sans";
          size = 11;
          weight = -1;
        };

        fontFixed = {
          family = "Noto Sans";
          size = 11;
          weight = -1;
        };
      };

      misc = {
        singleClickActivate = false;
        menusHaveIcons = true;
        shortcutsForContextMenus = true;
      };
    };
  };
}
