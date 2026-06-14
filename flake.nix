{
  description = "Amaan's Nix Configuration";
  nixConfig = {
    allow-import-from-derivation = false;
    auto-allocate-uids = true;
    extra-substituters = [
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    extra-experimental-features = [
      "auto-allocate-uids"
      "cgroups"
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
    accept-flake-config = true;
    builders-use-substitutes = true;
    flake-registry = "";
    http-connections = 50;
    show-trace = true;
    system-features = [
      "uid-range"
      "gccarch-la64v1.0"
    ];
    trusted-users = [
      "root"
      "@build"
      "@wheel"
      "@admin"
    ];
    use-cgroups = true;
    use-xdg-base-directories = true;
    warn-dirty = false;
    netrc-file = "/run/agenix/nixNetrc";
  };

  outputs =
    { self }:
    let
      tackInputs = import ./.tack;
      inputs = tackInputs // {
        inherit self;
      };

      inherit (builtins) readDir;
      inherit (inputs) nixpkgs nix-darwin;
      inherit (nixpkgs.lib)
        attrsToList
        const
        genAttrs
        groupBy
        listToAttrs
        mapAttrs
        ;
      lib' = nixpkgs.lib.extend (_: _: nix-darwin.lib);
      lib = lib'.extend <| import ./lib inputs;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

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
        |> mapAttrs (_: value: value.config);
    in
    hostsByType
    // hostConfigs
    // {
      inherit lib;

      apps = inputs.tombkey.lib.mkApps {
        nixosConfigurations = hostsByType.nixosConfigurations or { };
        darwinConfigurations = hostsByType.darwinConfigurations or { };
      };

      devShells = genAttrs systems (system: {
        default = (import nixpkgs { inherit system; }).mkShell {
          packages = [ inputs.tombkey.packages.${system}.default ];
        };
      });

      legacyPackages = genAttrs nixpkgs.lib.systems.doubles.linux (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnsupportedSystem = true;
        }
      );
    };
}
