{ pkgs, ... }:
{
  # RBE-compatible cache backend for Android builds (reclient)
  # Provides CAS + Action Cache over gRPC on port 9092
  systemd.services.bazel-remote = {
    description = "RBE-Compatible Bazel Remote Cache";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.bazel-remote}/bin/bazel-remote --dir /var/cache/bazel-remote --max_size 50 --enable_ac_key_instance_mangling --grpc_address 0.0.0.0:9092 --http_address 0.0.0.0:9091";
      User = "bazel-remote";
      Group = "bazel-remote";
      CacheDirectory = "bazel-remote";
    };
  };

  users.users.bazel-remote = {
    isSystemUser = true;
    group = "bazel-remote";
  };
  users.groups.bazel-remote = {};
}
