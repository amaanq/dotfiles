{
  config,
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib) enabled;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot = enabled;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth = enabled;
  boot.supportedFilesystems = [ "bcachefs" ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.i2c = enabled;
  hardware.keyboard.qmk = enabled;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
