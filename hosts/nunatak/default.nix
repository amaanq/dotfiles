lib:
lib.nixosSystem' "server" (
  {
    config,
    keys,
    lib,
    pkgs,
    ...
  }:
  let
    inherit (lib) collectNix enabled remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";

    secrets.id.rekeyFile = ./id.age;
    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };
    services.openssh.hostKeys = [
      {
        type = "ed25519";
        path = config.secrets.id.path;
      }
    ];

    secrets.password.rekeyFile = ./password.age;
    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };

      amaanq = {
        description = "Amaan Qureshi";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };

      rr = {
        description = "Reversed Rooms Team";
        isNormalUser = true;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      backup = {
        description = "Backup";
        isNormalUser = true;
        openssh.authorizedKeys.keys = keys.all;
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };
    };

    networking =
      let
        interface = "enp7s0";
      in
      {
        domain = "amaanq.com";

        hostName = "nunatak";

        ipv4.address = "152.53.83.122";
        ipv6.address = "2a0a:4cc0:2000:3f59::1";

        interfaces.${interface} = {
          ipv4.addresses = [
            {
              address = "152.53.31.156";
              prefixLength = 32;
            }
          ];

          # Second /64 routed via EUI-64 SLAAC; claim both so ND lands.
          ipv6.addresses = [
            {
              address = "2a0a:4cc0:2000:d000::1";
              prefixLength = 64;
            }
            {
              address = "2a0a:4cc0:2000:3f59:b41d:e8ff:fe20:96e1";
              prefixLength = 64;
            }
          ];
        };

        defaultGateway = {
          inherit interface;

          address = "152.53.80.1";
        };

        defaultGateway6 = {
          inherit interface;

          address = "fe80::1";
        };
      };

    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "25.11";

    time.timeZone = "Europe/Berlin";

    services.qemuGuest = enabled {
      # qemu-utils is a minimal working qemu, but it disables guestAgentSupport.
      # Force it back on to get the .ga output.
      package = (pkgs.qemu-utils.override { guestAgentSupport = true; }).ga;
    };
  }
)
