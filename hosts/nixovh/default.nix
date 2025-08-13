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

    networking = {
      domain = "vps.ovh.net";
      hostName = "nixovh";
      firewall = enabled {
        allowedTCPPorts = [
          22
          80
          443
          3000
        ];
      };
    };

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
        openssh.authorizedKeys.keys = keys.admins ++ [
          # Xeon's key
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6TGfa968DWRkqo0iBpEXaG62u7LlSaf4do1fVEDPCz xeon@reversedrooms"
        ];
        hashedPasswordFile = config.secrets.password.path;
        shell = pkgs.nushell;
      };

      rr = {
        description = "Reversed Rooms Team";
        extraGroups = [ "wheel" ];
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
        shell = pkgs.bash;
      };
    };

    home-manager.users = {
      root = { };
      rr = { };
    };

    system.stateVersion = "25.05";
    home-manager.sharedModules = [
      {
        home.stateVersion = "25.05";
      }
    ];

    time.timeZone = "Europe/Berlin";
  }
)
