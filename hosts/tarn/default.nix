lib:
lib.nixosSystem' "server" (
  {
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

    # Use stock kernel — bunker kernel patches are x86-specific
    bunker.kernel.enable = lib.mkForce false;
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    type = "server";

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      amaanq = {
        description = "Amaan Qureshi";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
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
