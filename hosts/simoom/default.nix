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
    builderSpeedFactor = 4;
    builderMaxJobs = 32;

    networking.hostName = "simoom";
    nixpkgs.config.allowUnfree = true;
    nix.enable = false;

    users.users.amaanq = {
      name = "amaanq";
      home = "/Users/amaanq";
    };

    system = {
      primaryUser = "amaanq";
      stateVersion = 5;
    };

    time.timeZone = "America/New_York";
  }
)
