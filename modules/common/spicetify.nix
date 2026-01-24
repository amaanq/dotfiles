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
    merge
    mkForce
    mkIf
    optionals
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
merge
<| mkIf config.isDesktop {
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

  nixpkgs.overlays = optionals config.isDarwin [
    (final: prev: {
      spotify = prev.spotify.overrideAttrs (oldAttrs: {
        src =
          if prev.stdenv.isAarch64 then
            prev.fetchurl {
              url = "https://web.archive.org/web/20251010104459/https://download.scdn.co/SpotifyARM64.dmg";
              hash = "sha256-0gwoptqLBJBM0qJQ+dGAZdCD6WXzDJEs0BfOxz7f2nQ=";
            }
          else
            prev.fetchurl {
              url = "https://web.archive.org/web/20251010104433/https://download.scdn.co/Spotify.dmg";
              hash = "sha256-8CrhLbnswbuAjRMaan2cTnnOMsr3vpW92IQ00KwPUHo=";
            };
      });
    })
  ];
}
