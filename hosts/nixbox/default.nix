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

    networking = {
      domain = "amaanq.com";
      hostName = "nixbox";
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
