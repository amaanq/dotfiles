{
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            label = "boot";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0022"
                "dmask=0022"
              ];
            };
          };
          root = {
            label = "nixos";
            size = "100%";
            content = {
              type = "bcachefs";
              filesystem = "root";
              label = "ssd.main";
            };
          };
        };
      };
    };

    bcachefs_filesystems.root = {
      type = "bcachefs_filesystem";
      passwordFile = "/tmp/scarp-bcachefs.key";
      mountpoint = "/";
      mountOptions = [
        "noatime"
        "lazytime"
      ];
      extraFormatArgs = [
        "--compression=lz4"
        "--background_compression=zstd:9"
        "--block_size=4096"
      ];
    };
  };
}
