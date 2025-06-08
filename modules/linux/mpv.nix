{ config, lib, ... }:
let
  inherit (lib)
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  home-manager.sharedModules = [
    {
      programs.mpv.enable = true;
    }
  ];
}
