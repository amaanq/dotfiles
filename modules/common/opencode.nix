{ config, lib, ... }:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  home-manager.sharedModules = [
    {
      programs.opencode = enabled;
    }
  ];
}
