{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge mkBefore;
  tokenFile = config.secrets.bazelRemoteToken.path;
  authConf = "/run/nginx/bazel-remote-auth.conf";
in
{
  imports = [ (self + /modules/nginx.nix) ];

  secrets.bazelRemoteToken = {
    file = ./token.age;
    owner = "nginx";
  };

  # RBE-compatible cache backend for Android builds (reclient)
  # Provides CAS + Action Cache over gRPC on port 9092
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

  # Generate nginx auth map from the agenix secret before nginx starts,
  # keeping the token out of the world-readable nix store.
  systemd.services.nginx.preStart = mkBefore ''
    TOKEN=$(cat ${tokenFile})
    printf 'map $http_x_rbe_token $rbe_auth_ok {\n  "%s" 1;\n  default 0;\n}\n' "$TOKEN" > ${authConf}
  '';

  services.nginx.appendHttpConfig = ''
    include ${authConf};
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
