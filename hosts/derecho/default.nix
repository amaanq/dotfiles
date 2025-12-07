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

    type = "desktop";
    isBuilder = true;
    builderSpeedFactor = 4;
    builderMaxJobs = 32;

    networking.hostName = "derecho";

    displayOutputs = {
      "DP-1" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 239.991;
        };
        scale = 1.25;
        position = {
          x = 3072;
          y = 0;
        };
      };
      "DP-2" = {
        mode = {
          width = 3840;
          height = 2160;
          refresh = 160.0;
        };
        scale = 1.25;
        position = {
          x = 0;
          y = 0;
        };
      };
    };

    secrets.password.file = ./password.age;
    users.users = {
      root = {
        openssh.authorizedKeys.keys = keys.admins;
        hashedPasswordFile = config.secrets.password.path;
      };

      amaanq = {
        description = "Amaan Qureshi";
        extraGroups = [
          "gamemode"
          "wheel"
        ];
        isNormalUser = true;
        hashedPasswordFile = config.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        shell = pkgs.nushell;
      };
    };

    home-manager.users = {
      root = { };
      amaanq = { };
    };

    system.stateVersion = "25.05";
    home-manager.sharedModules = [
      {
        home.stateVersion = "25.05";
      }
    ];

    time.timeZone = "America/New_York";
  }
)
