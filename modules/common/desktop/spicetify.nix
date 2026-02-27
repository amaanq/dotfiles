{
  config,
  spicetify,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    mkForce
    optionalAttrs
    theme
    ;

  colors = theme;

  spicetifyTheme = pkgs.writeTextFile {
    name = "color.ini";
    destination = "/color.ini";
    text = ''
      [base]
      text               = ${colors.text}
      subtext            = ${colors.text}
      main               = ${colors.base}
      main-elevated      = ${colors.overlay}
      highlight          = ${colors.overlay}
      highlight-elevated = ${colors.muted}
      sidebar            = ${colors.surface}
      player             = ${colors.subtle}
      card               = ${colors.muted}
      shadow             = ${colors.base}
      selected-row       = ${colors.subtle}
      button             = ${colors.subtle}
      button-active      = ${colors.subtle}
      button-disabled    = ${colors.muted}
      tab-active         = ${colors.overlay}
      notification       = ${colors.overlay}
      notification-error = ${colors.love}
      equalizer          = ${colors.pine}
      misc               = ${colors.overlay}
    '';
  };
in
{
  programs.spicetify =
    enabled {
      experimentalFeatures = true;
      enabledExtensions = with spicetify.legacyPackages.${config.hostSystem}.extensions; [
        copyLyrics
      ];
      theme = mkForce {
        name = "rose-pine";
        src = spicetifyTheme;
        sidebarConfig = false;
      };
      colorScheme = mkForce "base";
    }
    // optionalAttrs config.isLinux {
      wayland = true;
    };
}
