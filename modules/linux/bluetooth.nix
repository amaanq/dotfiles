{ config, lib, ... }:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  hardware.bluetooth = enabled {
    powerOnBoot = true;
  };
}
