{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    enabled
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  programs.adb = enabled;

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
