{ pkgs, nativelink, ... }:
let
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
          eviction_policy.max_bytes = 10 * gib;
        };
      }
      {
        name = "AC_CHECKED";
        completeness_checking = {
          backend.ref_store.name = "AC_MAIN";
          cas_store.ref_store.name = "CAS_MAIN";
        };
      }
    ];
    servers = [
      {
        listener.http.socket_address = "100.64.0.2:50051";
        listener.http.freebind = true;
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
              ac_store = "AC_CHECKED";
            }
          ];
          capabilities = [ { instance_name = "main"; } ];
          bytestream = [
            {
              instance_name = "main";
              cas_store = "CAS_MAIN";
            }
          ];
        };
      }
    ];
  };
in
{
  systemd.services.nativelink = {
    description = "A Nix-powered, high-performance build cache and remote execution server";
    after = [
      "network.target"
      "tailscaled.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${
        nativelink.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/nativelink ${nativelinkConfig}";
      Restart = "on-failure";
      RestartSec = 2;

      # systemd owns /var/cache/nativelink and re-chowns it on each start,
      # so the CAS survives restarts without a persistent account.
      DynamicUser = true;
      CacheDirectory = "nativelink";

      IPAddressAllow = [ "100.64.0.0/10" ];
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
}
