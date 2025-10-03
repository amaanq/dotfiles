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
    optionalAttrs
    ;
in
merge
<| mkIf config.isDesktop {
  programs.spicetify =
    enabled {
      experimentalFeatures = true;
      enabledExtensions = with spicetify.legacyPackages.${pkgs.stdenv.system}.extensions; [
        copyLyrics
      ];
    }
    // optionalAttrs config.isLinux {
      wayland = true;
    };
}
