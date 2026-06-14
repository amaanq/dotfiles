lib:
lib.nixosSystem' "server" (
  { keys, pkgs, ... }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";
    isBuilder = true;
    builderMaxJobs = 24;

    services.openssh.settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
      PrintLastLog = false;
    };

    # TODO(barchan bootstrap): shared password + circus token get rekeyed once
    # the boot-generated host key is registered in keys.nix. Until then this is
    # key-only. Add back: secrets.password.rekeyFile + hashedPasswordFile +
    # circus-agent.nix, then `nix run .#rekey`.
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

      backup = {
        description = "Backup";
        isNormalUser = true;
        openssh.authorizedKeys.keys = keys.all;
        shell = pkgs.nushell;
      };
    };

    networking = {
      hostName = "barchan";
      useDHCP = true;
    };

    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "26.05";

    time.timeZone = "America/New_York";
  }
)
