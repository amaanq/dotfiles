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

  fqdn = "gist.${domain}";
  port = stringToPort "gist";

  # Fix nixpkgs bug: stale npm-deps cache - rebuild from scratch
  src = pkgs.fetchFromGitHub {
    owner = "thomiceli";
    repo = "opengist";
    tag = "v1.11.1";
    hash = "sha256-TlUaen8uCj4Ba2gOWG32Gk4KIDvitXai5qv4PTeizYo=";
  };

  frontend' = pkgs.buildNpmPackage {
    pname = "opengist-frontend";
    version = "1.11.1";
    inherit src;
    patches = [ ./opengist-lockfile.patch ];

    postPatch = ''
      ${pkgs.lib.getExe pkgs.jq} '.version = "1.11.1"' package.json | ${pkgs.lib.getExe' pkgs.moreutils "sponge"} package.json
    '';

    postBuild = ''
      EMBED=1 npx postcss 'public/assets/embed-*.css' -c public/postcss.config.js --replace
    '';

    installPhase = ''
      mkdir -p $out
      cp -R public $out
    '';

    npmDepsHash = "sha256-6YLjhSOAJbowZOnfMCLEqW29NTSNqJRwGN/MJ1MpLjQ=";
  };

  opengist' = pkgs.buildGoModule {
    pname = "opengist";
    version = "1.11.1";
    inherit src;

    vendorHash = "sha256-NGRJuNSypmIc8G0wMW7HT+LkP5i5n/p3QH8FyU9pF5w=";
    tags = [ "fs_embed" ];
    ldflags = [
      "-s"
      "-X github.com/thomiceli/opengist/internal/config.OpengistVersion=v1.11.1"
    ];

    postPatch = ''
      cp -R ${frontend'}/public/{manifest.json,assets} public/
    '';

    doCheck = false;
  };
in
{
  imports = [
    (self + /modules/nginx.nix)
    (self + /modules/postgresql.nix)
  ];

  services.postgresql.ensure = [ "opengist" ];

  systemd.services.opengist = {
    description = "amaanq's gists";
    after = [
      "postgresql.service"
    ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      OG_LOG_LEVEL = "warn";
      OG_DB_URI = "postgres://opengist@127.0.0.1:5432/opengist?sslmode=disable";
      OG_HTTP_PORT = toString port;
      OG_HTTP_GIT_ENABLED = "false";
      OG_EXTERNAL_URL = "https://${fqdn}";
    };

    serviceConfig = {
      Type = "simple";
      User = "opengist";
      Group = "opengist";
      WorkingDirectory = "/var/lib/opengist";
      ExecStart = "${opengist'}/bin/opengist";
      Restart = "always";
      RestartSec = "10s";
    };

    path = [
      pkgs.git
      pkgs.openssh
    ];
  };

  users.users.opengist = {
    isSystemUser = true;
    group = "opengist";
    home = "/var/lib/opengist";
    createHome = true;
  };

  users.groups.opengist = { };

  systemd.tmpfiles.rules = [
    "d /var/lib/opengist 0755 opengist opengist -"
  ];

  services.nginx.virtualHosts.${fqdn} = merge config.services.nginx.sslTemplate {
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
