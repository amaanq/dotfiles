{ lib, ... }:
{
  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
    "xhci_pci"
    "usbhid"
    "usb_storage"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot = lib.enabled;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "bcachefs" ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = false;
  hardware.cpu.intel.updateMicrocode = true;
}
