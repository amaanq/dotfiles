{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf;
in
{
  config = mkIf config.isLaptop {
    services.asusd = enabled {
      enableUserService = true;
    };

    # supergfxctl needs pciutils to detect graphics cards
    systemd.services.supergfxd.path = [ pkgs.pciutils ];

    # Fine-grained NVIDIA power management for hybrid graphics
    hardware.nvidia.powerManagement.finegrained = true;
  };
}
