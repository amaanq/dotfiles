{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  programs.spicetify = enabled {
    wayland = true;
    experimentalFeatures = true;
    enabledExtensions = with inputs.spicetify.legacyPackages.${pkgs.stdenv.system}.extensions; [
      shuffle
      copyLyrics
    ];
  };
}
