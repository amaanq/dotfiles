{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # OSUOSL OpenStack POWER10 presents disks via virtio-scsi (hw_disk_bus=scsi)
        # so the boot volume is /dev/sda, not /dev/vda.
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # PReP boot: raw GRUB ieee1275 core.elf (no filesystem).
            # Installed manually via `grub-mkimage -O powerpc-ieee1275 | dd`
            # after nixos-install — `boot.loader.grub.enable = false` because
            # NixOS's install-grub.sh pulls perl XML-LibXML which breaks cross.
            prep = {
              size = "8M";
              type = "4100";
            };
            # GRUB ieee1275 can't read bcachefs, so /boot lives on ext2
            # (ext2 only — ext4 metadata_csum breaks GRUB's embedded driver).
            boot = {
              size = "1G";
              type = "8300";
              content = {
                type = "filesystem";
                format = "ext2";
                mountpoint = "/boot";
                mountOptions = [ "noatime" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                # bcachefs works on ppc64 BE once bcachefs-tools' BLKGETSIZE64
                # ioctl encoding is fixed (3-bit dir / 13-bit size on ppc/mips/
                # sparc); we apply that patch in cross-ppc64-fixes.nix until
                # upstream merges Kent's tree.
                format = "bcachefs";
                mountpoint = "/";
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
