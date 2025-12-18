{ lib, pkgs, ... }:
let
  inherit (lib) enabled;

  embedEtcdConfig = pkgs.writeText "embedEtcd.yaml" ''
    listen-client-urls: http://0.0.0.0:2379
    advertise-client-urls: http://0.0.0.0:2379
    quota-backend-bytes: 4294967296
    auto-compaction-mode: revision
    auto-compaction-retention: '1000'
  '';
in
{
  virtualisation.podman = enabled {
    dockerCompat = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.milvus = {
      image = "milvusdb/milvus:v2.6.7";
      cmd = [
        "milvus"
        "run"
        "standalone"
      ];
      environment = {
        ETCD_USE_EMBED = "true";
        ETCD_DATA_DIR = "/var/lib/milvus/etcd";
        ETCD_CONFIG_PATH = "/milvus/configs/embedEtcd.yaml";
        COMMON_STORAGETYPE = "local";
        DEPLOY_MODE = "STANDALONE";
      };
      ports = [ "19530:19530" ];
      volumes = [
        "milvus_data:/var/lib/milvus"
        "${embedEtcdConfig}:/milvus/configs/embedEtcd.yaml:ro"
      ];
      extraOptions = [ "--security-opt=seccomp:unconfined" ];
      autoStart = true;
    };
  };
}
