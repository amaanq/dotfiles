{
  description = "Amaan's Nix Configuration";
  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io/"
      "https://cache.privatevoid.net"
      "https://nix-community.cachix.org/"
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    extra-experimental-features = [
      "cgroups"
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
    accept-flake-config = true;
    builders-use-substitutes = true;
    flake-registry = "";
    http-connections = 50;
    lazy-trees = true;
    show-trace = true;
    trusted-users = [
      "root"
      "@build"
      "@wheel"
      "@admin"
    ];
    use-cgroups = true;
    warn-dirty = false;
  };

  inputs = {
    nix = {
      url = "github:DeterminateSystems/nix-src";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bindiff = {
      url = "github:amaanq/bindiff";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hkpoolservices = {
      url = "git+https://git.amaanq.com/amaanq/hkpoolservices.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";

      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";

      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "nix-darwin";
      inputs.home-manager.follows = "home-manager";
    };

    github2forgejo = {
      url = "github:RGBCube/GitHub2Forgejo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ida-pro-overlay = {
      url = "github:msanft/ida-pro-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-config = {
      url = "github:amaanq/nvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crash = {
      url = "github:RGBCube/crash";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    thorium = {
      url = "github:amaanq/thorium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:amaanq/niri-flake/default-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    buckMaterialShell = {
      url = "github:amaanq/BuckMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:amaanq/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hjem = {
    #   url = "github:feel-co/hjem";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hjem-rum = {
    #   url = "path:/home/amaanq/projects/hjem-rum";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.hjem.follows = "hjem";
    # };
  };

  outputs =
    inputs@{ nixpkgs, nix-darwin, ... }:
    let
      inherit (builtins) readDir;
      inherit (nixpkgs.lib)
        attrsToList
        const
        groupBy
        listToAttrs
        mapAttrs
        nameValuePair
        ;
      lib' = nixpkgs.lib.extend (const: const: nix-darwin.lib);
      lib = lib'.extend <| import ./lib inputs;

      hostsByType =
        readDir ./hosts
        |> mapAttrs (name: const <| import ./hosts/${name} lib)
        |> attrsToList
        |> groupBy (
          { value, ... }:
          if value ? class && value.class == "nixos" then "nixosConfigurations" else "darwinConfigurations"
        )
        |> mapAttrs (const listToAttrs);

      hostConfigs =
        hostsByType.darwinConfigurations or { } // hostsByType.nixosConfigurations or { }
        |> attrsToList
        |> map ({ name, value }: nameValuePair name value.config)
        |> listToAttrs;
    in
    hostsByType
    // hostConfigs
    // {
      inherit lib;
    };
}
