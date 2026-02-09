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
    cpuArch = "MZEN3";
    isLaptop = true;

    networking.hostName = "lahar";

    displayOutputs = {
      "eDP-1" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 165.0;
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

    system.stateVersion = "25.11";

    time.timeZone = "America/New_York";
  }
)
