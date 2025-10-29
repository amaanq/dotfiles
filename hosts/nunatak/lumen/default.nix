{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge stringToPort;

  fqdn = "re.${domain}";
  lumenPort = stringToPort "lumen";
  apiPort = stringToPort "lumen-api";

  lumenPackage = pkgs.rustPlatform.buildRustPackage {
    pname = "lumen";
    version = "0.2.0";

    src = pkgs.fetchFromGitHub {
      owner = "naim94a";
      repo = "lumen";
      rev = "master";
      hash = "sha256-2oHD+Znpm+/gJdQrnIEQ+QHIR8kwvNjE6VT+Vgxs5B4=";
    };

    cargoHash = "sha256-oN6ijJivBmzrxQIF33fO/d83ngzNxFOmZ3KYfDQhocQ=";

    nativeBuildInputs = [
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.openssl
      pkgs.postgresql
    ];

    checkFlags = [
      "--skip=db"
    ];

    meta = {
      description = "A private Lumina server for IDA Pro";
      homepage = "https://github.com/naim94a/lumen";
      license = lib.licenses.mit;
      maintainers = [ ];
      mainProgram = "lumen";
    };
  };

  configFile = pkgs.writeText "lumen-config.toml" ''
    [lumina]
    bind_addr = "[::1]:${toString lumenPort}"
    use_tls = false
    server_name = "lumen"
    allow_deletes = false
    get_history_limit = 50

    [database]
    connection_info = "postgres://lumen@/lumen?host=/run/postgresql"
    use_tls = false

    [api_server]
    bind_addr = "[::1]:${toString apiPort}"
  '';
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  services.postgresql.ensure = [ "lumen" ];

  systemd.services.lumen = {
    description = "Lumen - Private Lumina Server for IDA Pro";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "postgresql.service"
    ];
    requires = [ "postgresql.service" ];

    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "lumen";
      ExecStart = "${lumenPackage}/bin/lumen -c ${configFile}";
      Restart = "on-failure";

      # Hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations = {
      "/".proxyPass = "http://[::1]:${toString lumenPort}";

      "/api/".proxyPass = "http://[::1]:${toString apiPort}/";
    };

    extraConfig = ''
      proxy_read_timeout 300s;
      proxy_connect_timeout 75s;
    '';
  };
}
