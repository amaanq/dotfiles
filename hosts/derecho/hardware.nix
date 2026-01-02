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

  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
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
  boot.kernelModules = [
    "ddcci_backlight"
    "i2c-dev"
    "kvm-amd"
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = enabled {
    pkiBundle = "/var/lib/sbctl";
  };
  boot.plymouth = enabled;
  boot.supportedFilesystems = [ "bcachefs" ];

  fileSystems."/" = {
    device = "UUID=fef71188-998b-4a00-a263-6b525fe9832b";
    fsType = "bcachefs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.i2c = enabled;
  hardware.keyboard.qmk = enabled;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  # Workaround for RX 9070 power management crash (https://gitlab.freedesktop.org/drm/amd/-/issues/4829)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="high"
  '';

  environment.systemPackages = [
    pkgs.sbctl
  ];
}
