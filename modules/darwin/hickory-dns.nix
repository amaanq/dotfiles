{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled singleton;
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types)
    listOf
    path
    port
    str
    submodule
    ;

  cfg = config.services.hickory-dns;
  toml = pkgs.formats.toml { };
  hostname = config.networking.hostName;

  hickoryPackage =
    let
      version = "0.26.0-alpha.1";
      src = pkgs.fetchFromGitHub {
        owner = "hickory-dns";
        repo = "hickory-dns";
        rev = "8065bacde2ed02dfa7fd5019b50882bdb8a88475";
        hash = "sha256-7aO4p4Kh0B18jIaB6R1UkZHWkGMbdhwos5CsEOymyxQ=";
      };
    in
    pkgs.hickory-dns.overrideAttrs (old: {
      inherit version src;
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-pVuCZjKzQlN36oBDs2CJtRN6DWxOp2iQkyGC/06gG1Y=";
      };
      cargoBuildFeatures = old.cargoBuildFeatures or [ ] ++ [
        "h3-aws-lc-rs"
        "https-aws-lc-rs"
      ];
      # nixpkgs marks hickory-dns linux-only; the build itself works on darwin.
      meta = old.meta // {
        platforms = old.meta.platforms ++ lib.platforms.darwin;
      };
      # tests open real sockets; fail in sandbox.
      checkFlags = (old.checkFlags or [ ]) ++ [
        "--skip=client_tests::test_nsec3_no_data"
        "--skip=h2::h2_client_stream::tests::test_https_google"
        "--skip=h2::h2_client_stream::tests::test_https_google_with_pure_ip_address_server"
      ];
    });
in
{
  options.services.hickory-dns = {
    enable = mkEnableOption "hickory-dns";
    package = mkPackageOption pkgs "hickory-dns" { } // {
      default = hickoryPackage;
    };
    configFile = mkOption {
      type = path;
      default = toml.generate "hickory-dns.toml" cfg.settings;
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
            type = listOf toml.type;
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
          /bin/wait4path /nix/store && exec ${getExe' cfg.package "hickory-dns"} --config ${cfg.configFile}
        ''
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  # Mirror the linux config: nextdns over DoH/DoQ for everything, MagicDNS UDP
  # for the headscale zone. Listen only on loopback; system resolver via ::1.
  config.services.hickory-dns = enabled {
    settings = {
      listen_port = 53;
      listen_addrs_ipv4 = singleton "127.0.0.53";
      listen_addrs_ipv6 = singleton "::1";

      zones = [
        {
          zone = "cirque.amaanq.com";
          zone_type = "External";
          stores = {
            type = "forward";
            name_servers = singleton {
              ip = "100.100.100.100";
              trust_negative_responses = true;
              connections = singleton {
                protocol.type = "udp";
              };
            };
            options = {
              cache_size = 1024;
              positive_max_ttl = 300;
              negative_max_ttl = 300;
            };
          };
        }
        {
          zone = ".";
          zone_type = "External";
          stores = {
            type = "forward";
            name_servers =
              let
                mkNextDnsServer = ip: {
                  inherit ip;
                  trust_negative_responses = true;
                  connections = [
                    {
                      protocol = {
                        server_name = "dns.nextdns.io";
                        path = "/9b2c13/${hostname}";
                        type = "h3";
                      };
                    }
                    {
                      protocol = {
                        server_name = "dns.nextdns.io";
                        path = "/9b2c13/${hostname}";
                        type = "https";
                      };
                    }
                    {
                      protocol = {
                        server_name = "${hostname}-9b2c13.dns.nextdns.io";
                        type = "quic";
                      };
                    }
                    {
                      protocol = {
                        server_name = "${hostname}-9b2c13.dns.nextdns.io";
                        type = "tls";
                      };
                    }
                  ];
                };
              in
              [
                (mkNextDnsServer "2a07:a8c0::")
                (mkNextDnsServer "2a07:a8c1::")
                (mkNextDnsServer "45.90.28.0")
                (mkNextDnsServer "45.90.30.0")
              ];
            options = {
              cache_size = 32768;
              num_concurrent_reqs = 4;
              positive_min_ttl = 60;
              positive_max_ttl = 86400;
              negative_min_ttl = 900;
              negative_max_ttl = 86400;
            };
          };
        }
      ];
    };
  };
}
