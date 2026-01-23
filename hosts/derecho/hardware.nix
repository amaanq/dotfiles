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
  boot.initrd.kernelModules = [ "amdgpu" ];
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

  # RDNA 4 (RX 9070) MES scheduler hang workaround
  # See: https://github.com/ROCm/ROCm/issues/3207
  boot.kernelParams = [
    "amdgpu.mcbp=0" # Disable mid-command buffer preemption (primary MES fix)
    "amdgpu.sg_display=0" # Disable scatter-gather display (reduces TLB pressure)
    "amdgpu.gpu_recovery=1" # Auto-recover from hangs if they still occur
  ];

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

  # Realtek RTL8125 NIC workarounds - disable offloading and EEE to fix driver issues
  systemd.services.ethtool-enp18s0 = {
    description = "Configure ethtool settings for enp18s0";
    after = [ "sys-subsystem-net-devices-enp18s0.device" ];
    wantedBy = [ "sys-subsystem-net-devices-enp18s0.device" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ethtool-enp18s0" ''
        ${pkgs.ethtool}/bin/ethtool -K enp18s0 gso off gro off tso off
        ${pkgs.ethtool}/bin/ethtool --set-eee enp18s0 eee off
        ${pkgs.ethtool}/bin/ethtool -A enp18s0 autoneg off rx off tx off
      '';
    };
  };

  environment.systemPackages = [
    pkgs.sbctl
  ];
}
