lib:
lib.nixosSystem' "server" (
  {
    config,
    keys,
    pkgs,
    lib,
    ...
  }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";
    isBuilder = true;
    builderMaxJobs = 16;

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    # nushell.nix module now enabled (was previously stubbed); it generates
    # /etc/nushell/config.nu and env.nu via its derivations.

    # common/nix.nix (disabledModules) normally enables nix-command + flakes
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.trusted-users = [ "max" ];

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
      hostName = "tarn";
      useDHCP = true;
    };

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
    # GRUB managed manually on PReP partition — disable NixOS installer
    # (install-grub.sh requires perl XML-LibXML which breaks in cross-compilation)
    boot.loader.grub.enable = lib.mkForce false;
    boot.supportedFilesystems = [ "bcachefs" ];
    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "25.11";

    time.timeZone = "America/Los_Angeles";
  }
)
