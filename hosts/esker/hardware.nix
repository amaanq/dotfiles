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
  boot.extraModulePackages = [ config.boot.kernelPackages.framework-laptop-kmod ];

  bunker.kernel.framework = true;

  # Fix PSR hangs and graphics issues on AMD AI 300 series.
  # https://gist.github.com/lbrame/f9034b1a9fe4fc2d2835c5542acb170a
  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x410"
    "amdgpu.sg_display=0"
    "amdgpu.abmlevel=0"
  ];

  # Ethernet expansion card USB autosuspend.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
  '';

  boot.loader.systemd-boot = enabled;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth = enabled;
  boot.supportedFilesystems = [ "bcachefs" ];

  # 8GB dirty page cap for Android builds.
  boot.kernel.sysctl."vm.dirty_bytes" = 8 * 1024 * 1024 * 1024;
  boot.kernel.sysctl."vm.dirty_background_bytes" = 2 * 1024 * 1024 * 1024;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.i2c = enabled;
  hardware.keyboard.qmk = enabled;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
