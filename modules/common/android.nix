{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = attrValues {
    inherit (pkgs) android-tools;

    inherit (pkgs.androidenv.androidPkgs)
      emulator
      ndk-bundle
      platform-tools
      tools
      ;
  };
}
