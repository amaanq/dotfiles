lib:
lib.nixosSystem' (
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

    networking.hostName = "nixmain";

    users.users.amaanq = {
      isNormalUser = true;
      extraGroups = [
        "adbusers"
        "networkmanager"
        "wheel"
      ];
    };

    time.timeZone = "America/New_York";

    system.stateVersion = "25.05";
    home-manager.users.amaanq = {
      home.stateVersion = "25.05";
    };

    nixpkgs.config.allowUnfree = true;
  }
)
