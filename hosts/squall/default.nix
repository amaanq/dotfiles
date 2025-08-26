lib:
lib.darwinSystem' (
  { lib, ... }:
  let
    inherit (lib) collectNix remove;
  in
  {
    imports = collectNix ./. |> remove ./default.nix;

    type = "desktop";

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
        home.stateVersion = "25.05";
      }
    ];

    time.timeZone = "America/New_York";
  }
)
