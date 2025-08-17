{
  config,
  inputs,
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
      enabledExtensions = with inputs.spicetify.legacyPackages.${pkgs.stdenv.system}.extensions; [
        shuffle
        copyLyrics
      ];
    }
    // optionalAttrs config.isLinux {
      wayland = true;
    };
}
