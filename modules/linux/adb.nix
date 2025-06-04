{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  programs.adb.enable = config.isLinux;
}
