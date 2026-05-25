{
  self,
  config,
  lib,
  pkgs,
  nativelink,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge;

  gib = 1024 * 1024 * 1024;

  nativelinkConfig = (pkgs.formats.json { }).generate "nativelink.json5" {
    stores = [
      {
        name = "CAS_FS";
        filesystem = {
          content_path = "/var/cache/nativelink/cas";
          temp_path = "/var/cache/nativelink/cas-tmp";
          eviction_policy.max_bytes = 150 * gib;
        };
      }
      {
        # size+hash verification on write keeps the CAS honest
        name = "CAS_MAIN";
        verify = {
          backend.ref_store.name = "CAS_FS";
          verify_size = true;
          verify_hash = true;
        };
      }
      {
        name = "AC_MAIN";
        filesystem = {
          content_path = "/var/cache/nativelink/ac";
          temp_path = "/var/cache/nativelink/ac-tmp";
          eviction_policy.max_bytes = 2 * gib;
        };
      }
    ];
    servers = [
      {
        # plaintext h2c as nginx terminates TLS and grpc_pass-es here
        listener.http.socket_address = "127.0.0.1:50051";
        services = {
          cas = [
            {
              instance_name = "main";
              cas_store = "CAS_MAIN";
            }
          ];
          ac = [
            {
              instance_name = "main";
              ac_store = "AC_MAIN";
            }
          ];
          capabilities = [ { instance_name = "main"; } ];
          bytestream.cas_stores.main = "CAS_MAIN";
        };
      }
    ];
  };
in
{
  imports = [ (self + /modules/nginx.nix) ];

  secrets.nativelinkAuthMap = {
    rekeyFile = ./auth-map.age;
    owner = "nginx";
    mode = "0440";
  };

  # RBE cache backend for Android + Chromium builds:
  systemd.services.nativelink = {
    description = "A Nix-powered, high-performance build cache and remote execution server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${nativelink.packages.${pkgs.system}.default}/bin/nativelink ${nativelinkConfig}";
      Restart = "on-failure";
      RestartSec = 2;

      # systemd owns /var/cache/nativelink and re-chowns it on each start,
      # so the CAS survives restarts without a persistent account.
      DynamicUser = true;
      CacheDirectory = "nativelink";

      # Only nginx (loopback) reaches the :50051 listener. When this moves to a
      # tailnet bind, widen IPAddressAllow to the tailnet CIDR instead.
      IPAddressAllow = [ "localhost" ];
      IPAddressDeny = [ "any" ];

      AmbientCapabilities = [ "" ];
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      UMask = "0077";
    };
  };

  services.nginx.appendHttpConfig = ''
    include ${config.secrets.nativelinkAuthMap.path};
  '';

  services.nginx.virtualHosts."android.${domain}" = merge config.services.nginx.sslTemplate {
    extraConfig = ''
      client_max_body_size 4G;
      grpc_read_timeout 600s;
      grpc_send_timeout 600s;
    '';
    locations."/" = {
      extraConfig = ''
        if ($rbe_auth_ok = 0) {
          return 403;
        }
        client_max_body_size 4G;
        grpc_pass grpc://127.0.0.1:50051;
      '';
    };
  };
}
