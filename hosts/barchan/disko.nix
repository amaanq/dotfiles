{
  # Targets the board's INTERNAL NVMe. On the desktop it currently enumerates
  # as /dev/sdc (USB adapter) — do NOT run disko against this on the desktop;
  # provision on the board where it's /dev/nvme0n1. Unencrypted like nunatak
  # (unattended builder — no unlock step at boot).
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/";
                mountOptions = [ "noatime" ];
                extraArgs = [
                  "--block_size=16384"
                  "--compression=lz4"
                  "--background_compression=zstd:9"
                ];
              };
            };
          };
        };
      };
    };
  };
}
