{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.kdePackages.qt6ct
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.rose-pine-kvantum
  ];

  home-manager.sharedModules = [
    {
      qt = enabled {
        platformTheme.name = "qtct";
        style.name = "kvantum";
      };

      xdg.configFile = {
        "qt6ct/qt6ct.conf".text = ''
          [Appearance]
          standard_dialogs=xdgdesktopportal
          style=kvantum-dark

          [Interface]
          activate_item_on_single_click=1
          buttonbox_layout=0
          cursor_flash_time=1000
          dialog_buttons_have_icons=1
          double_click_interval=400
          gui_effects=@Invalid()
          keyboard_scheme=2
          menus_have_icons=true
          show_shortcuts_in_context_menus=true
          stylesheets=@Invalid()
          toolbutton_style=4
          underline_shortcut=1
          wheel_scroll_lines=3

          [SettingsWindow]
          geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\f\0\0\0\0\0\0\0\x17\xe7\0\0\x6\x84\0\0\f\0\0\0\0\0\0\0\x17\xe7\0\0\x6\x84\0\0\0\0\x2\0\0\0\f\0\0\0\f\0\0\0\0\0\0\0\x17\xe7\0\0\x6\x84)

          [Troubleshooting]
          force_raster_widgets=0
          ignored_applications=@Invalid()
        '';

        "Kvantum/kvantum.kvconfig".text = ''
          [General]
          theme=rose-pine-iris
        '';
      }
      // (
        let
          themesPath = "${pkgs.rose-pine-kvantum}/share/Kvantum/themes";
          themeNames = builtins.attrNames (builtins.readDir themesPath);
        in
        builtins.listToAttrs (
          map (themeName: {
            name = "Kvantum/${themeName}";
            value.source = "${themesPath}/${themeName}";
          }) themeNames
        )
      );
    }
  ];
}
