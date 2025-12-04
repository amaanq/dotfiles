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
    pkgs.gef
    pkgs.imhex
    pkgs.patchelf
    pkgs.radare2
    pkgs.rizin
    pkgs.rizinPlugins.rz-ghidra
    pkgs.yara
  ]
  ++ optionals config.isLinux [
    pkgs.pwninit
  ];

  home-manager.sharedModules = [
    {
      home.sessionVariables.RZ_LIB_PLUGINS = "${pkgs.rizinPlugins.rz-ghidra}/lib/rizin/plugins";
    }
  ];
}
