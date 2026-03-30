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

    networking =
      let
        interface = "enp7s0";
      in
      {
        domain = "amaanq.com";

        hostName = "nunatak";

        ipv4.address = "152.53.83.122";
        ipv6.address = "2a0a:4cc0:2000:3f59::1";

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
