{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  boot.kernelModules = [
    "vfio-pci"
  ];
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids="
  ];

  environment = {
    systemPackages = [
      pkgs.virt-viewer
      pkgs.virtio-win
      pkgs.looking-glass-client
      pkgs.win-spice
    ];
  };

  home-manager.sharedModules = [
    {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    }
  ];

  programs.dconf = enabled;
  programs.virt-manager = enabled;

  services.spice-vdagentd = enabled;

  users.users.amaanq = {
    extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };

  virtualisation = {
    waydroid = enabled;

    libvirtd = enabled {
      qemu = {
        package = pkgs.qemu;
        swtpm = enabled;
        ovmf = enabled {
          packages = [ pkgs.OVMFFull.fd ];
        };
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };

    spiceUSBRedirection = enabled;
  };
}
