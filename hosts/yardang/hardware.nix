_: {
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "mptspi"
    "sd_mod"
    "sr_mod"
    "uhci_hcd"
    "ehci_pci"
    "vmxnet3"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.supportedFilesystems = [ "bcachefs" ];

  boot.tmp.cleanOnBoot = true;

  networking.useDHCP = false;
  networking.interfaces.ens160.useDHCP = false;
}
