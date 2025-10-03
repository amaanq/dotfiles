{
  config,
  lanzaboote,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    lanzaboote.nixosModules.lanzaboote
  ];

  boot.extraModulePackages = [ ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = enabled {
    pkiBundle = "/var/lib/sbctl";
  };
  boot.plymouth = enabled;

  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp16s0.useDHCP = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.i2c = enabled;
  hardware.keyboard.qmk = enabled;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  environment.systemPackages = [
    pkgs.sbctl
  ];
}
