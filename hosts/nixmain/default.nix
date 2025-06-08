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
    nixpkgs.config.allowUnfree = true;

    users.users.amaanq = {
      description = "Amaan Qureshi";
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      shell = pkgs.nushell;
    };

    home-manager.users = {
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
