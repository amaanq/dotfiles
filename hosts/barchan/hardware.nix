{ lib, ... }:
{
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];

  boot.loader.systemd-boot = lib.enabled;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.hostPlatform = "loongarch64-linux";

  hasKvm = false;

  networking.useDHCP = true;
}
