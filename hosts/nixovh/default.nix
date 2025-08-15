lib:
lib.nixosSystem' (
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
    isConstrained = true;

    secrets.id.file = ./id.age;
    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
    services.openssh.hostKeys = [
      {
        type = "ed25519";
        path = config.secrets.id.path;
      }
    ];

    secrets.password.file = ./password.age;
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
        openssh.authorizedKeys.keys = keys.admins ++ [
          # Xeon's key
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6TGfa968DWRkqo0iBpEXaG62u7LlSaf4do1fVEDPCz xeon@reversedrooms"

          # Hpdev's key
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFV14ihNidwax9+bCvsUuceMWjOH7RFjQ9Lllh4KvIhB hpdevfox@meow.hpdevfox.ru"

          # Xavo's key
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJC9J7XFAHsjygyZuckhmbr0IZybBZMHjEnYFmDvZYRb xeondev-git-xavo95"

          # Zihad's keys
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE5vEUAeQijm37+OvGgdQ3/cLMOS5hHdAuQTYbJCAUWx zihad@sora"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcVH8aHNDVPUADwzQWA5DYgLvpFUezy4eMWtOO8Oopi zihad@sora"
        ];
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

    home-manager.users = {
      root = { };
      amaanq = { };
      rr = { };
      backup = { };
    };

    networking = {
      domain = "amaanq.com";

      hostName = "nixovh";

      enableIPv6 = true;

      interfaces.ens3.ipv6.addresses = [
        {
          address = "2001:41d0:701:1100::6a06";
          prefixLength = 64;
        }
      ];

      defaultGateway6 = {
        address = "2001:41d0:701:1100::1";
        interface = "ens3";
      };

      firewall = enabled {
        allowedTCPPorts = [
          22
          25
          53
          143
          443
          465
          587
          993
        ];
        allowedUDPPorts = [
          53
          60001
        ];
      };
    };

    system.stateVersion = "25.05";
    home-manager.sharedModules = [
      {
        home.stateVersion = "25.05";
      }
    ];

    time.timeZone = "Europe/Berlin";

    swapDevices = [
      {
        device = "/var/swapfile";
        size = 2048; # 2GB
      }
    ];
  }
)
