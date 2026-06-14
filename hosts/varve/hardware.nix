{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) disabled enabled mkForce;
in
{
  # 26.11 removed the platform.linux-kernel attr (lib.systems.elaborate throws on
  # it). The kernel target auto-derives to "vmlinux" for mips (build.nix keys off
  # linuxArch), linuxArch resolves to "mips" from the config triple, and the base
  # defconfig is now passed by bunkernel's buildLinux (defconfig=cavium_octeon_defconfig).
  nixpkgs.hostPlatform = "mips64-unknown-linux-gnuabi64";
  nixpkgs.buildPlatform = "x86_64-linux";

  # arch/mips/Makefile's install target appends -$(KERNELRELEASE) to the image.
  # kernelFile reads kernel.target, which is auto-detected as "vmlinux" for mips.
  system.boot.loader.kernelFile = "vmlinux-${config.boot.kernelPackages.kernel.modDirVersion}";

  # Cavium Octeon III CN7360. The pure-Clang octeon kernel carries the PKO3/BGX
  # ethernet stack, the dwc3 USB-host fixes, and netfilter/nftables + TUN.
  bunker.kernel = {
    octeon = true;
    lto = "none";
  };

  # The octeon kernel builds the USB/xhci/dwc3/storage stack and ext4 in (=y),
  # so the initrd needs no modules at all; mkForce [ ] drops the nixpkgs x86
  # defaults.
  boot.initrd.availableKernelModules = lib.mkForce [ ];
  boot.initrd.kernelModules = lib.mkForce [ ];

  boot.initrd.systemd.enable = true;

  # tftp-kernel.nix unpacks this initrd with gunzip before re-embedding it
  # uncompressed in the vmlinux, so it must be gzip, not the zstd default.
  boot.initrd.compressor = "gzip";
  boot.initrd.compressorArgs = [
    "-9"
    "-n"
  ];

  # Plain unencrypted ext4 root on the 128GB USB stick (whole-disk, no partition
  # table so the kernel needs no partition parser). bcachefs was dropped: its
  # copygc/btree-merge path BUGs on mips64 BE, and ext4 is in-tree and bulletproof
  # here. No encryption means the box boots with no passphrase or embedded key.
  fileSystems."/" = {
    device = "/dev/disk/by-label/EDGE_ROOT";
    fsType = "ext4";
    options = [ "x-systemd.device-timeout=90s" ];
  };
  boot.supportedFilesystems = lib.mkForce [ "ext4" ];

  # No on-disk bootloader: Cavium U-Boot loads the kernel directly. systemd-boot
  # (pulled by the server profile) has no install target here and otherwise
  # aborts switch-to-configuration trying to write a nonexistent /boot.
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.kernelParams = [ "console=ttyS0,115200" ];

  # The server profile points nameservers at systemd-resolved's stub
  # (127.0.0.53), but resolved is disabled here, so DNS resolves to a dead local
  # address. Use real upstream resolvers (8.8.8.8 appears blocked on this LAN).
  networking.nameservers = lib.mkForce [
    "1.1.1.1"
    "9.9.9.9"
  ];

  # The octeon BGX driver's TX/RX checksum + segmentation offload corrupts routed
  # TCP/UDP: DNS and TLS to the internet fail (ICMP, kernel-checksummed, works).
  # Disable offload on every octeon NIC at boot.
  systemd.services.octeon-disable-offload = {
    description = "Disable broken octeon BGX checksum/segmentation offload";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "octeon-disable-offload" ''
        for i in $(seq 0 8); do
          ${pkgs.ethtool}/bin/ethtool -K "eth$i" \
            tx off rx off tso off gso off gro off sg off 2>/dev/null || true
        done
      '';
    };
  };

  # ttyS0 is the only console; autologin root for a network-less serial shell.
  services.getty.autologinUser = "root";
  systemd.services."serial-getty@ttyS0" = enabled;
  systemd.services."getty@tty1" = mkForce disabled;
}
