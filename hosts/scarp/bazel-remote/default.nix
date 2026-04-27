{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge;
in
{
  imports = [ (self + /modules/nginx.nix) ];

  secrets.bazelRemoteAuthMap = {
    rekeyFile = ./auth-map.age;
    owner = "nginx";
    mode = "0440";
  };

  # RBE-compatible cache backend for Android builds w/ reclient,
  # which provides CAS + Action Cache over gRPC on port 9092
  systemd.services.bazel-remote = {
    description = "RBE-Compatible Bazel Remote Cache";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.bazel-remote}/bin/bazel-remote --dir /var/cache/bazel-remote --max_size 50 --enable_ac_key_instance_mangling --grpc_address 127.0.0.1:9092 --http_address 127.0.0.1:9091";
      User = "bazel-remote";
      Group = "bazel-remote";
      CacheDirectory = "bazel-remote";
    };
  };

  services.nginx.appendHttpConfig = ''
    include ${config.secrets.bazelRemoteAuthMap.path};
  '';

  services.nginx.virtualHosts."android.${domain}" = merge config.services.nginx.sslTemplate {
    locations."/" = {
      extraConfig = ''
        if ($rbe_auth_ok = 0) {
          return 403;
        }
        grpc_pass grpc://127.0.0.1:9092;
      '';
    };
  };

  users.users.bazel-remote = {
    isSystemUser = true;
    group = "bazel-remote";
  };
  users.groups.bazel-remote = { };
}
