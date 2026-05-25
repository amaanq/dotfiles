{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.kernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "sr_mod"
  ];

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="vd[a-z]", ATTR{queue/rotational}="0", ATTR{queue/read_ahead_kb}="32768"
  '';

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.buildPlatform = "x86_64-linux";

  hasKvm = false;

  boot.tmp.cleanOnBoot = true;
}
