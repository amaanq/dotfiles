{
  self,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrsToList
    concatStringsSep
    const
    disabled
    filter
    filterAttrs
    flip
    id
    isType
    mapAttrs
    mapAttrsToList
    merge
    mkAfter
    optionalAttrs
    optionals
    ;
  inherit (lib.strings) toJSON;
  registryMap = inputs |> filterAttrs (const <| isType "flake");
in
{
  # Store flake inputs to prevent garbage collection
  environment.etc.".system-inputs.json".text = toJSON registryMap;

  nix.distributedBuilds = true;
  nix.buildMachines =
    self.nixosConfigurations
    |> attrsToList
    |> filter ({ name, value }: name != config.networking.hostName && value.config.users.users ? build)
    |> map (
      { name, value }:
      {
        hostName = name;
        maxJobs = 20;
        protocol = "ssh-ng";
        sshUser = "build";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        system = value.config.nixpkgs.hostPlatform.system;
      }
    );

  nix.channel = disabled;

  nix.gc =
    merge {
      automatic = !config.isDarwin;
      options = "--delete-older-than 3d";
    }
    <| optionalAttrs config.isLinux {
      dates = "weekly";
      persistent = true;
    };

  nix.nixPath =
    registryMap
    |> mapAttrsToList (name: value: "${name}=${value}")
    |> (if config.isDarwin or false then concatStringsSep ":" else id);

  nix.registry =
    registryMap // { default = inputs.nixpkgs; } |> mapAttrs (_: flake: { inherit flake; });

  nix.settings =
    (import (self + /flake.nix)).nixConfig
    |> flip removeAttrs (optionals (config.isDarwin or false) [ "use-cgroups" ]);

  nix.optimise.automatic = !config.isDarwin;

  environment.systemPackages = [
    pkgs.nh
    pkgs.nix-index
    pkgs.nix-output-monitor
  ];

  # Add nushell helpers
  home-manager.sharedModules = [
    {
      programs.nushell.configFile.text =
        # nu
        mkAfter ''
          def --wrapped nr [program: string = "", ...arguments] {
            if ($program | str contains "#") or ($program | str contains ":") {
              nix run $program -- ...$arguments
            } else {
              nix run ("default#" + $program) -- ...$arguments
            }
          }
          def --wrapped ns [...programs] {
            nix shell ...($programs | each {
              if ($in | str contains "#") or ($in | str contains ":") {
                $in
              } else {
                "default#" + $in
              }
            })
          }
        '';
    }
  ];
}
