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
    "android-sdk-emulator"
    "android-sdk-ndk"
    "android-sdk-platform-tools"
    "android-sdk-tools"
  ];

  environment.systemPackages = [
    pkgs.android-tools
    pkgs.androidenv.androidPkgs.ndk-bundle
    pkgs.androidenv.androidPkgs.platform-tools
    pkgs.androidenv.androidPkgs.tools
  ]
  ++ optionals config.isLinux [
    pkgs.android-udev-rules
  ];
}
