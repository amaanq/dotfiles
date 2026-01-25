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
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "server";
    isBuilder = true;
    builderMaxJobs = 12;

    networking = {
      domain = "amaanq.com";
      hostName = "scarp";
    };
    nixpkgs.config.allowUnfree = true;

    secrets.id.file = ./id.age;
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
      };

      amaanq = {
        description = "Amaan Qureshi";
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };

      backup = {
        description = "Backup";
        openssh.authorizedKeys.keys = keys.all;
        hashedPasswordFile = config.secrets.password.path;
        isNormalUser = true;
      };
    };

    system.stateVersion = "25.11";

    time.timeZone = "America/New_York";
  }
)
