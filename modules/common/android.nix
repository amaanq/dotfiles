{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    merge
    mkIf
    optionals
    ;
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "android-sdk-ndk"
    "android-sdk-platform-tools"
    "platform-tools"
    "ndk"
  ];

  environment.systemPackages = [
    pkgs.android-tools
    pkgs.androidenv.androidPkgs.ndk-bundle
    pkgs.androidenv.androidPkgs.platform-tools
  ];
}
