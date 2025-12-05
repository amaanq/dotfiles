{
  self,
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  builderKeyPath = config.secrets.builderKey.path;
  inherit (lib)
    attrsToList
    concatMapStringsSep
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

  builderHosts =
    (self.nixosConfigurations // (self.darwinConfigurations or { }))
    |> attrsToList
    |> filter ({ name, value }: name != config.networking.hostName && value.config.users.users ? build)
    |> map (
      { name, value }:
      {
        inherit name;
        port = value.config.services.openssh.ports or [ 22 ] |> builtins.head;
      }
    );
in
{
  secrets.builderKey.file = ./builder-key.age;

  # Store flake inputs to prevent garbage collection
  environment.etc.".system-inputs.json".text = toJSON registryMap;

  nix.distributedBuilds = true;
  nix.buildMachines =
    let
      mkMachines =
        configs: extraFeatures:
        configs
        |> attrsToList
        |> filter ({ name, value }: name != config.networking.hostName && value.config.users.users ? build)
        |> map (
          { name, value }:
          let
            hostSystem = value.config.nixpkgs.hostPlatform.system;
            emulatedSystems = value.config.boot.binfmt.emulatedSystems or [ ];
          in
          {
            hostName = name;
            maxJobs = value.config.builderMaxJobs;
            protocol = "ssh-ng";
            speedFactor = value.config.builderSpeedFactor;
            sshKey = builderKeyPath;
            sshUser = "build";
            supportedFeatures = [
              "benchmark"
              "big-parallel"
            ]
            ++ extraFeatures;
            systems = [ hostSystem ] ++ emulatedSystems;
          }
        );
    in
    mkMachines self.nixosConfigurations [
      "kvm"
      "nixos-test"
    ]
    ++ mkMachines (self.darwinConfigurations or { }) [ ];

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

  programs.ssh.extraConfig =
    builderHosts
    |> concatMapStringsSep "\n" (
      { name, port }:
      ''
        Host ${name}
          Port ${toString port}
          StrictHostKeyChecking accept-new
      ''
    );

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
