{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf merge;
in
merge
<| mkIf config.isDesktop {
  programs.dconf = enabled;

  home-manager.sharedModules = [
    {
      gtk = enabled {
        gtk3.extraCss = config.theme.adwaitaGtkCss;
        gtk4.extraCss = config.theme.adwaitaGtkCss;

        gtk3.extraConfig = {
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintslight";
          gtk-xft-rgba = "rgb";
          gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
          gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
          gtk-button-images = 0;
          gtk-menu-images = 0;
          gtk-enable-event-sounds = 1;
          gtk-enable-input-feedback-sounds = 0;
        };

        font = {
          inherit (config.theme.font.sans) name package;

          size = config.theme.font.size.normal;
        };

        iconTheme = config.theme.icons;

        theme = {
          name = "rose-pine";
          package = pkgs.rose-pine-gtk-theme;
        };
      };
    }
  ];
}
