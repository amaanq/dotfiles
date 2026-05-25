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
    isBuilder = true;
    builderMaxJobs = 96;

    networking = {
      domain = "amaanq.com";
      hostName = "guyot";
    };

    secrets.id.rekeyFile = ./id.age;
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
      };

      amaanq = {
        description = "Amaan Qureshi";
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };
    };

    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "26.05";

    time.timeZone = "America/New_York";
  }
)
