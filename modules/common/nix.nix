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

  # lowdown 2.0.2's Makefile doesn't have the variables the cygwin patch expects
  # (LIB_LOWDOWN, MAIN_OBJS, etc.) - those were added in 2.0.4
  # Remove the patch since we're not on Cygwin anyway
  lowdownOverlay = _: prev: {
    lowdown = prev.lowdown.overrideAttrs { patches = [ ]; };
  };

  inherit (lib)
    attrsToList
    concatMapStringsSep
    concatStringsSep
    const
    disabled
    escapeShellArg
    filter
    filterAttrs
    flip
    id
    isType
    length
    mapAttrs
    mapAttrsToList
    merge
    mkAfter
    mkIf
    optionalAttrs
    optionals
    zipListsWith
    ;
  inherit (lib.strings) toJSON;

  nix-output-monitor =
    let
      oldIcons = [
        "↑"
        "↓"
        "⏱"
        "⏵"
        "✔"
        "⏸"
        "⚠"
        "∅"
        "∑"
      ];
      newIcons = [
        "f062" #
        "f063" #
        "f520" #
        "f04b" #
        "f00c" #
        "f04c" #
        "f071" #
        "f1da" #
        "f04a0" # 󰒠
      ];
      zippedIcons = zipListsWith (a: b: "s/${a}/\\\\x${b}/") oldIcons newIcons;
    in
    assert length oldIcons == length newIcons;
    pkgs.nix-output-monitor.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        sed -i ${escapeShellArg (concatStringsSep "\n" zippedIcons)} lib/NOM/Print.hs
        substituteInPlace lib/NOM/Print/Tree.hs --replace-fail '┌' '╭'
      '';
    });

  nh = pkgs.nh.override { inherit nix-output-monitor; };
  registryMap = inputs |> filterAttrs (const <| isType "flake");

  # Resolve hostname via tailscale, connect with netcat
  tailscale-proxy = pkgs.writeScript "tailscale-proxy" ''
    #!${pkgs.nushell}/bin/nu
    def main [host: string, port: int] {
      let ip = try {
        tailscale status --json
        | from json
        | get Peer
        | values
        | where { $in.HostName | str downcase | str starts-with ($host | str downcase) }
        | first
        | get TailscaleIPs.0
      } catch { $host }
      ${pkgs.libressl.nc}/bin/nc $ip $port
    }
  '';

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
  nixpkgs.overlays = [ lowdownOverlay ];

  secrets.builderKey.file = ./builder-key.age;
  secrets.githubToken = {
    file = ./github-token.age;
    mode = "0444";
  };

  nix.extraOptions = ''
    !include ${config.secrets.githubToken.path}
  '';

  # Store flake inputs to prevent garbage collection
  environment.etc.".system-inputs.json".text = toJSON registryMap;

  # Only servers use distributed builds to avoid circular delegation deadlocks
  # See: https://github.com/NixOS/nix/issues/10740
  nix.distributedBuilds = config.type == "server";
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
    nh
    nix-output-monitor
    pkgs.nix-index
  ];

  programs.ssh.extraConfig =
    builderHosts
    |> concatMapStringsSep "\n" (
      { name, port }:
      ''
        Host ${name}
          Port ${toString port}
          ConnectTimeout 3
          ConnectionAttempts 1
          StrictHostKeyChecking accept-new
      ''
      # Servers use distributed builds, resolve via tailscale to avoid DNS → Cloudflare timeouts
      + lib.optionalString config.isServer "      ProxyCommand ${tailscale-proxy} %h ${toString port}\n"
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
