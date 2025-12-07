{
  lib,
  modulesPath,
  ...
}:
let
  inherit (lib) enabled;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  unfree.allowedNames = [
    "nvidia-settings"
    "nvidia-x11"
  ];

  kernelArch = "MZEN3";

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.loader.systemd-boot = enabled;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth = enabled;
  boot.supportedFilesystems = [ "bcachefs" ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  hardware.graphics = enabled;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting = enabled;
    powerManagement = enabled;
    open = false;
    nvidiaSettings = true;
    prime = {
      offload = enabled {
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
