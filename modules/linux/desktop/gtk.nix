{
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
    gtk-icon-theme-name=${config.theme.icons.name}
    gtk-font-name=${config.theme.font.sans.name} ${toString config.theme.font.size.normal}
    gtk-xft-antialias=1
    gtk-xft-hinting=1
    gtk-xft-hintstyle=hintslight
    gtk-xft-rgba=rgb
    gtk-toolbar-style=GTK_TOOLBAR_ICONS
    gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
    gtk-button-images=0
    gtk-menu-images=0
    gtk-enable-event-sounds=1
    gtk-enable-input-feedback-sounds=0
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = ''
    [Settings]
    gtk-icon-theme-name=${config.theme.icons.name}
    gtk-font-name=${config.theme.font.sans.name} ${toString config.theme.font.size.normal}
  '';

  programs.dconf = enabled {
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            icon-theme = config.theme.icons.name;
            font-name = "${config.theme.font.sans.name} ${toString config.theme.font.size.normal}";
            color-scheme = "prefer-dark";
          };
        };
      }
    ];
  };
}
