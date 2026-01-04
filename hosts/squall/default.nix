lib:
lib.darwinSystem' (
  { lib, ... }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "desktop";
    isBuilder = true;

    networking.hostName = "squall";
    nixpkgs.config.allowUnfree = true;
    nix.enable = false;

    users.users.amaanq = {
      name = "amaanq";
      home = "/Users/amaanq";
    };

    home-manager.users = {
      amaanq = { };
    };

    system = {
      primaryUser = "amaanq";
      stateVersion = 5;
    };
    home-manager.sharedModules = [
      {
        home.stateVersion = "25.11";
      }
    ];

    time.timeZone = "America/New_York";
  }
)
