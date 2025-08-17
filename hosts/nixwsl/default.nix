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

    type = "desktop";
    isVirtual = true;

    wsl = enabled {
      defaultUser = "amaanq";
    };

    networking.hostName = "nixwsl";

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
