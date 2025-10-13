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
  environment.systemPackages = [
    pkgs.apktool
    pkgs.binwalk
    # Keystone is broken
    # pkgs.gef
    # ImHex is broken (CMake edlib compatibility issue)
    # pkgs.imhex
    pkgs.patchelf
    pkgs.radare2
    pkgs.yara
  ]
  ++ optionals config.isLinux [
    pkgs.pwninit

  ];
}
