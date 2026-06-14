{
  self,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) domain;
  inherit (lib) merge;

  fqdn = "signal.${domain}";
  port = 8181;
  source = inputs.signal-web;
  nodejsUnicode17Slim = pkgs.nodejs-slim_24.override {
    callPackage = lib.callPackageWith (pkgs // { icu = pkgs.icu78; });
  };
  nodejsUnicode17 = pkgs.callPackage "${pkgs.path}/pkgs/development/web/nodejs/symlink.nix" {
    nodejs-slim = nodejsUnicode17Slim;
  };

  updateSignalWeb = pkgs.writeShellScript "signal-web-update" ''
    set -euo pipefail

    rm -rf /var/lib/signal-web/source.new
    mkdir -p /var/lib/signal-web/source.new
    cp -a --reflink=auto ${source}/. /var/lib/signal-web/source.new/
    chmod -R u+w /var/lib/signal-web/source.new
    rm -rf /var/lib/signal-web/source
    mv /var/lib/signal-web/source.new /var/lib/signal-web/source

    cd /var/lib/signal-web/source
    ${pkgs.pnpm}/bin/pnpm install --frozen-lockfile
    ${pkgs.pnpm}/bin/pnpm run build:protobuf
    ${pkgs.pnpm}/bin/pnpm run build:emoji-data
    ${pkgs.pnpm}/bin/pnpm --filter @signal-web/headless build
  '';
in
{
  imports = [ (self + /modules/nginx.nix) ];

  secrets.signalWebEnv.rekeyFile = ./signal-web.env.age;

  users.users."signal-web" = {
    isSystemUser = true;
    group = "signal-web";
    home = "/var/lib/signal-web";
    createHome = true;
  };
  users.groups."signal-web" = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/signal-web 0750 signal-web signal-web -"
    "d /var/lib/signal-web/data 0700 signal-web signal-web -"
  ];

  systemd.services."signal-web" = {
    description = "Signal Web self-hosted PWA";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      HOME = "/var/lib/signal-web";
      SIGNAL_WEB_DATA_DIR = "/var/lib/signal-web/data";
      SIGNAL_WEB_PORT = toString port;
      SIGNAL_WEB_PUBLIC_ORIGIN = "https://${fqdn}";
      SIGNAL_WEB_SECURE_COOKIES = "true";
      SIGNAL_WEB_TRUST_PROXY = "true";
      LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.alsa-lib
        pkgs.libpulseaudio
      ];
    };

    serviceConfig = {
      Type = "simple";
      User = "signal-web";
      Group = "signal-web";
      WorkingDirectory = "/var/lib/signal-web";
      EnvironmentFile = config.secrets.signalWebEnv.path;
      ExecStartPre = updateSignalWeb;
      ExecStart = "${nodejsUnicode17}/bin/node /var/lib/signal-web/source/packages/headless/dist/main.mjs";
      Restart = "on-failure";
      RestartSec = "10s";
      StateDirectory = "signal-web";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/signal-web" ];
    };

    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.gcc
      pkgs.gnumake
      nodejsUnicode17
      pkgs.python3
      pkgs.pnpm
    ];
  };

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
  };
}
