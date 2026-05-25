{
  config,
  lib,
  utils,
  keys,
  ...
}:
let
  inherit (lib) enabled;
in
{
  boot.initrd.availableKernelModules = [
    "usb_storage"
    "uas"
    "ext4"
    "e1000e"
  ];

  boot.initrd = {
    systemd = enabled {
      mounts = [
        {
          where = "/key";
          what = "/dev/disk/by-label/bootkey";
          type = "ext4";
          options = "ro";
          unitConfig.DefaultDependencies = false;
        }
      ];

      services."unlock-bcachefs-${utils.escapeSystemdPath "/"}" = {
        requires = [ "key.mount" ];
        after = [ "key.mount" ];
        script = lib.mkForce ''
          ${config.boot.bcachefs.package}/bin/bcachefs unlock "${config.fileSystems."/".device}" < /key/.bcachefs.key
        '';
      };

      network = enabled {
        networks."10-wired" = {
          matchConfig.Type = "ether";
          networkConfig.DHCP = "yes";
        };
      };

      services.sshd = {
        after = [ "key.mount" ];
        requires = [ "key.mount" ];
        unitConfig.RequiresMountsFor = [ "/key/.initrd_ssh_host_key" ];
        preStart = lib.mkForce "";
      };
    };

    network.ssh = enabled {
      port = 2222;
      hostKeys = [ "/key/.initrd_ssh_host_key" ];
      authorizedKeys = keys.admins;
    };

    secrets = lib.mkForce { };
  };
}
