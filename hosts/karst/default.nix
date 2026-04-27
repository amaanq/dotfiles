lib:
lib.nixosSystem' "server" (
  {
    config,
    keys,
    pkgs,
    ...
  }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

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
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      max = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHynM2pDVAe8ZlooMYFBTAhoEW1lV066GtoxjJJ0qEs6AAAAB3NzaDptYXg= max@privatevoid.net"
        ];
      };

      lillis = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIYWWRfOsSpi7M6ejCEWHGTtsvOA8v7FiUOBR2If1nVa will.lillis24@gmail.com"
        ];
      };
    };

    networking = {
      hostName = "karst";
      useDHCP = true;
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "25.11";

    time.timeZone = "America/Los_Angeles";
  }
)
