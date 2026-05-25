{
  self,
  config,
  inputs,
  lib,
  options,
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
    escapeShellArg
    filter
    filterAttrs
    isType
    length
    mapAttrs
    mapAttrsToList
    mkForce
    mkIf
    optionalAttrs
    optionals
    optionalString
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
        "f062" # 
        "f063" # 
        "f520" # 
        "f04b" # 
        "f00c" # 
        "f04c" # 
        "f071" # 
        "f1da" # 
        "f04a0" # 󰒠
      ];
      zippedIcons = zipListsWith (a: b: "s/${a}/\\\\x${b}/") oldIcons newIcons;
    in
    assert length oldIcons == length newIcons;
    pkgs.nix-output-monitor.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + /* sh */ ''
        sed -i ${escapeShellArg (concatStringsSep "\n" zippedIcons)} lib/NOM/Print.hs
        substituteInPlace lib/NOM/Print/Tree.hs --replace-fail '┌' '╭'
      '';
    });

  # nom fails on cross builds and ppc64 via GHC Template Haskell.
  isCross = pkgs.stdenv.buildPlatform != pkgs.stdenv.hostPlatform;
  isPower64 = pkgs.stdenv.hostPlatform.isPower64 or false;
  inherit (config)
    isDarwin
    isDesktop
    isLinux
    isServer
    ;

  statixConfig = pkgs.writeText "statix.toml" /* toml */ ''disabled = ["repeated_keys"]'';
  statixPatched = pkgs.statix.overrideAttrs (
    _o:
    let
      src = pkgs.fetchFromGitHub {
        owner = "oppiliappan";
        repo = "statix";
        rev = "e9df54ce918457f151d2e71993edeca1a7af0132";
        hash = "sha256-duH6Il124g+CdYX+HCqOGnpJxyxOCgWYcrcK0CBnA2M=";
      };
    in
    {
      inherit src;
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-IeVGsrTXqmXbKRbJlBDv02fJ+rPRjwuF354/jZKRK/M=";
      };
      postPatch = /* sh */ ''
        substituteInPlace bin/src/config.rs \
          --replace-fail 'default_value = "."' 'default_value = ".", env = "STATIX_CONFIG"'
      '';
    }
  );

  registryMap = inputs |> filterAttrs (const <| isType "flake");
  registryMapForHost =
    registryMap
    |> filterAttrs (name: _: !isServer || name == "nixpkgs")
    |> (registries: registries // { default = inputs.nixpkgs; });

  nixPathFormatters = optionals isDarwin [ (concatStringsSep ":") ];
  formatNixPath = paths: nixPathFormatters |> builtins.foldl' (value: format: format value) paths;

  # Resolve hostname via tailscale, connect with netcat
  tailscale-proxy = pkgs.writeScript "tailscale-proxy" /* nu */ ''
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
  secrets.builderKey.rekeyFile = ./builder-key.age;
  secrets.githubToken =
    {
      rekeyFile = ./github-token.age;
    }
    |> (
      secret:
      secret
      // optionalAttrs isLinux {
        mode = "0440";
        group = "wheel";
      }
    )
    |> (
      secret:
      secret
      // optionalAttrs (!isLinux) {
        owner = "amaanq";
        mode = "0400";
      }
    );

  nix.extraOptions = ''
    !include ${config.secrets.githubToken.path}
  '';

  # Store flake inputs to prevent garbage collection
  environment.etc = mkIf (!isServer) {
    ".system-inputs.json".text = toJSON registryMap;
  };

  # Only servers use distributed builds to avoid circular delegation deadlocks
  # See: https://github.com/NixOS/nix/issues/10740
  nix.distributedBuilds = isServer;
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
      "uid-range"
    ]
    ++ mkMachines (self.darwinConfigurations or { }) [ ];

  nix.channel = disabled;

  nix.gc =
    {
      automatic = !isDarwin;
      options = "--delete-older-than 3d";
    }
    |> (
      gc:
      gc
      // optionalAttrs isLinux {
        dates = "weekly";
        persistent = true;
      }
    );

  nix.nixPath =
    registryMap
    |> mapAttrsToList (name: value: "${name}=${value}")
    |> formatNixPath
    |> mkIf (!isServer);

  nix.registry = registryMapForHost |> mapAttrs (_: flake: { inherit flake; });

  nix.settings =
    (import (self + /flake.nix)).nixConfig
    |> (
      settings:
      removeAttrs settings (
        optionals isDarwin [
          "use-cgroups"
          "system-features"
          "auto-allocate-uids"
        ]
      )
    )
    |> (
      settings:
      settings
      // optionalAttrs (!isDarwin) (
        let
          default = (options.nix.settings.type.getSubOptions [ ]).system-features.default;
        in
        {
          system-features = mkForce (
            (default |> filter (feature: feature != "kvm" || config.hasKvm))
            ++ (import (self + /flake.nix)).nixConfig.system-features
          );
        }
      )
    );

  nix.optimise.automatic = !isDarwin;

  nix.package = pkgs.nixVersions.latest;

  wrappers.statix = {
    basePackage = statixPatched;
    systemWide = true;
    executables.statix.environment.STATIX_CONFIG.value = "${statixConfig}";
  };

  environment.systemPackages = [
    pkgs.nix-index
  ]
  ++ optionals isDesktop [
    (pkgs.callPackage (inputs.tack + "/nix/package.nix") { })
  ]
  ++ optionals (!isCross || isPower64) [
    pkgs.nh
  ]
  ++ optionals (!isCross && !isPower64) [
    nix-output-monitor
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
      + optionalString isServer "      ProxyCommand ${tailscale-proxy} %h ${toString port}\n"
    );

}
