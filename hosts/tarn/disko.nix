{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "8M";
              type = "4100";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = null;
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
                  "--compression=zstd:9"
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
