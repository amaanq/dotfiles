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
    mkIf
    optionals
    optionalAttrs
    ;
in
merge
<| mkIf config.isDesktop {
  programs.spicetify =
    enabled {
      experimentalFeatures = true;
      enabledExtensions = with spicetify.legacyPackages.${config.hostSystem}.extensions; [
        copyLyrics
      ];
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
