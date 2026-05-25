{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  boot.supportedFilesystems = [ "bcachefs" ];

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.buildPlatform = "x86_64-linux";

  hasKvm = false;

  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = false;
}
