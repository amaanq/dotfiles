lib:
lib.darwinSystem' (
  {
    config,
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

    networking.hostName = "nixbook";
    nixpkgs.config.allowUnfree = true;
    nix.enable = false;

    users.users.amaanq = {
      name = "amaanq";
      home = "/Users/amaanq";
    };

    home-manager.users.amaanq = {
      home.stateVersion = "25.05";
    };

    system = {
      primaryUser = "amaanq";
      stateVersion = 5;
    };

    time.timeZone = "America/New_York";
  }
)
