{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge;

  name = "oxicloud";
  fqdn = "drive.${domain}";
  port = 8086;
  dataDir = "/var/lib/${name}";
in
{
  services.postgresql.ensure = [ name ];

  users.users.${name} = {
    isSystemUser = true;
    group = name;
    home = dataDir;
  };
  users.groups.${name} = { };

  secrets.oxicloudJwt = {
    rekeyFile = ./oxicloud-jwt.age;
    owner = name;
  };

  systemd.tmpfiles.rules = [ "d ${dataDir}/storage 0700 ${name} ${name} -" ];

  systemd.services.${name} = {
    description = "OxiCloud";
    after = [
      "postgresql.service"
      "network.target"
    ];
    wants = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      OXICLOUD_SERVER_HOST = "127.0.0.1";
      OXICLOUD_SERVER_PORT = toString port;
      OXICLOUD_STORAGE_PATH = "${dataDir}/storage";
      OXICLOUD_BASE_URL = "https://${fqdn}";
      OXICLOUD_DB_CONNECTION_STRING = "postgres:///${name}?host=/run/postgresql";
      OXICLOUD_COOKIE_SECURE = "true";
      OXICLOUD_DISABLE_REGISTRATION = "true";
      OXICLOUD_MAX_UPLOAD_SIZE = toString (32 * 1024 * 1024 * 1024);
    };

    serviceConfig = {
      User = name;
      Group = name;
      ExecStart = "${pkgs.oxicloud}/bin/oxicloud";
      EnvironmentFile = config.secrets.oxicloudJwt.path;
      WorkingDirectory = dataDir;
      StateDirectory = name;
      Restart = "always";
      RestartSec = 5;
      SyslogIdentifier = name;

      ReadWritePaths = [ "/run/postgresql" ];

      AmbientCapabilities = [ "" ];
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = false;
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

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    extraConfig = ''
      ${config.services.nginx.headers}
      client_max_body_size 0;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = "proxy_cookie_path off;";
    };
  };
}
