{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;
  inherit (lib.attrsets)
    filterAttrs
    isAttrs
    mapAttrs
    ;
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.strings) escapeShellArgs;
  inherit (lib.lists) isList map;
  inherit (lib.types)
    either
    enum
    listOf
    nullOr
    path
    port
    str
    submodule
    ;

  cfg = config.services.hickory-dns;
  toml = pkgs.formats.toml { };
  cleanToml =
    value:
    if isList value then
      map cleanToml value
    else if isAttrs value then
      value |> filterAttrs (_: value: value != null) |> mapAttrs (_: cleanToml)
    else
      value;

  # nixpkgs marks hickory-dns linux-only; the build itself works on darwin.
  hickoryPackage = pkgs.hickory-dns.overrideAttrs (old: {
    meta = old.meta // {
      platforms = old.meta.platforms ++ lib.platforms.darwin;
    };
  });
in
{
  options.services.hickory-dns = {
    enable = mkEnableOption "hickory-dns";
    package = mkPackageOption pkgs "hickory-dns" { } // {
      default = hickoryPackage;
    };
    configFile = mkOption {
      type = either path str;
      default = toml.generate "hickory-dns.toml" <| cleanToml cfg.settings;
    };
    settings = mkOption {
      type = submodule {
        freeformType = toml.type;
        options = {
          listen_addrs_ipv4 = mkOption {
            type = listOf str;
            default = [ ];
          };
          listen_addrs_ipv6 = mkOption {
            type = listOf str;
            default = [ ];
          };
          listen_port = mkOption {
            type = port;
            default = 53;
          };
          zones = mkOption {
            type =
              listOf
              <| submodule (
                { config, ... }:
                {
                  freeformType = toml.type;
                  options = {
                    zone = mkOption {
                      type = str;
                    };
                    zone_type = mkOption {
                      type = enum [
                        "Primary"
                        "Secondary"
                        "External"
                      ];
                      default = "Primary";
                    };
                    file = mkOption {
                      type = nullOr (either path str);
                      default = if config.zone_type != "External" then "${config.zone}.zone" else null;
                    };
                  };
                }
              );
            default = [ ];
          };
        };
      };
    };
  };

  config.launchd.daemons.hickory-dns = mkIf cfg.enable {
    # wait4path /nix/store keeps the daemon from racing the nix volume mount
    # after a fresh boot.
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        /* bash */ ''
          /bin/wait4path /nix/store && exec ${
            escapeShellArgs [
              (getExe' cfg.package "hickory-dns")
              "--config"
              cfg.configFile
            ]
          }
        ''
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  config.services.hickory-dns = enabled { settings = config.dns.hickorySettings; };
}
