{
  lib,
  pkgs,
  nativelink,
  ...
}:
let
  inherit (lib) concatLists zipAttrs;

  gib = 1024 * 1024 * 1024;

  mkInstance =
    name:
    let
      cas = {
        instance_name = name;
        cas_store = "${name}-cas";
      };
    in
    {
      stores = [
        {
          name = "${name}-cas-fs";
          filesystem = {
            content_path = "/var/cache/nativelink/${name}/cas";
            temp_path = "/var/cache/nativelink/${name}/cas-tmp";
            eviction_policy.max_bytes = 150 * gib;
          };
        }
        {
          # size+hash verification on write keeps the CAS honest
          name = "${name}-cas";
          verify = {
            backend.ref_store.name = "${name}-cas-fs";
            verify_size = true;
            verify_hash = true;
          };
        }
        {
          name = "${name}-ac-fs";
          filesystem = {
            content_path = "/var/cache/nativelink/${name}/ac";
            temp_path = "/var/cache/nativelink/${name}/ac-tmp";
            eviction_policy.max_bytes = 10 * gib;
          };
        }
        {
          name = "${name}-ac";
          completeness_checking = {
            backend.ref_store.name = "${name}-ac-fs";
            cas_store.ref_store.name = "${name}-cas";
          };
        }
      ];
      inherit cas;
      bytestream = cas;
      ac = {
        instance_name = name;
        ac_store = "${name}-ac";
      };
      capabilities = {
        instance_name = name;
      };
    };

  instances = [
    "android"
    "chromium"
  ];

  perInstance = zipAttrs (map mkInstance instances);

  nativelinkConfig = (pkgs.formats.json { }).generate "nativelink.json5" {
    stores = concatLists perInstance.stores;
    servers = [
      {
        listener.http.socket_address = "100.64.0.2:50051";
        listener.http.freebind = true;
        services = {
          inherit (perInstance)
            cas
            ac
            capabilities
            bytestream
            ;
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
