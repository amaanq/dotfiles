{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  services.asusd = enabled {
    enableUserService = true;
  };

  # supergfxctl needs pciutils to detect graphics cards
  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  # Fine-grained NVIDIA power management for hybrid graphics
  hardware.nvidia.powerManagement.finegrained = true;
}
