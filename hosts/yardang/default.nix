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
    inherit (lib) collectNix remove;
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
        interface = "ens160";
      in
      {
        domain = "amaanq.com";

        hostName = "yardang";

        ipv4.address = "45.87.120.62";
        ipv4.prefixLength = 24;

        defaultGateway = {
          inherit interface;

          address = "45.87.120.1";
        };
      };

    boot.tmp.cleanOnBoot = true;

    # BIOS VMware → grub is mandatory → grub's install-grub.sh is perl.
    # Nothing we can do about it short of reimplementing the installer.
    system.forbiddenDependenciesRegexes = lib.mkForce [ ];

    system.stateVersion = "25.11";

    time.timeZone = "Europe/Istanbul";
  }
)
