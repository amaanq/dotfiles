{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "virtio_pci"
    "virtio_scsi"
    "usbhid"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ "nvme" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot.tmp.cleanOnBoot = true;

  networking.useDHCP = false;
  networking.interfaces.enp7s0.useDHCP = false;

  networking.nameservers = [ "127.0.0.53" ];
}
