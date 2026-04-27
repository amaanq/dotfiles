{
  self,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.networking) domain;
  inherit (lib) enabled;

  domains = [
    "amaanq.com"
    "ameerq.com"
    "libg.so"
    "hkpoolservices.com"
  ];

  acmeRoot = "/var/lib/acme/${domain}";

  mkListener =
    {
      cid,
      name,
      bind,
      protocol,
      tlsImplicit ? false,
      useTls ? true,
    }:
    {
      "@type" = "create";
      object = "NetworkListener";
      value.${cid} = {
        inherit name protocol;
        bind = lib.listToAttrs (
          map (addr: {
            name = addr;
            value = true;
          }) bind
        );
        useTls = useTls;
        tlsImplicit = tlsImplicit;
      };
    };
in
{
  imports = [
    (self + /modules/services/stalwart.nix)
    (self + /modules/acme)
  ];

  secrets.stalwartPassword.rekeyFile = ./password.plain.age;
  secrets.stalwartAmeerqPassword.rekeyFile = ./ameerq-password.plain.age;
  secrets.stalwartHkPassword.rekeyFile = ./hk-password.plain.age;
  secrets.stalwartDkimKey.rekeyFile = ./dkim-stalwart.key.age;
  secrets.stalwartRecoveryPassword.rekeyFile = ./recovery-password.plain.age;
  secrets.stalwartAdminPassword = {
    rekeyFile = ./admin-password.plain.age;
    owner = "stalwart-mail";
    group = "stalwart-mail";
    mode = "0440";
  };

  services.postgresql.ensure = [ "stalwart-mail" ];

  users.users.stalwart-mail.extraGroups = [ "acme" ];

  # On cert renewal stalwart's parse_certificates() keeps the cached DB
  # notValidAfter until `stalwart-cli update Certificate <id>` is run.
  security.acme.certs.${domain}.reloadServices = [ "stalwart.service" ];

  services.nginx.virtualHosts =
    lib.genAttrs
      [
        "mail.${domain}"
        domain
        "ameerq.com"
        "libg.so"
        "hkpoolservices.com"
      ]
      (
        _:
        config.services.nginx.sslTemplate
        // {
          locations."/.well-known/jmap" = {
            proxyPass = "http://[::1]:8080/.well-known/jmap";
            extraConfig = ''
              proxy_set_header Host mail.${domain};
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };

          locations."/jmap" = {
            proxyPass = "http://[::1]:8080/jmap";
            extraConfig = ''
              proxy_set_header Host mail.${domain};
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              client_max_body_size 50M;
            '';
          };
        }
      );

  services.stalwart = enabled {
    user = "stalwart-mail";
    group = "stalwart-mail";
    dataDir = "/var/lib/stalwart-mail";

    credentials.dkim_key = config.secrets.stalwartDkimKey.path;

    openFirewall = true;
    firewallPorts = [
      25
      80
      143
      443
      465
      587
      993
    ];

    dataStore = {
      "@type" = "PostgreSql";
      host = "localhost";
      port = 5432;
      database = "stalwart-mail";
      authUsername = "stalwart-mail";
      authSecret = {
        "@type" = "None";
      };
      timeout = 15000;
      poolMaxConnections = 10;
    };

    # Listeners aren't carried over by the 0.16 migration; declare them here.
    plan = [
      (mkListener {
        cid = "listener-smtp";
        name = "smtp";
        bind = [ "[::]:25" ];
        protocol = "smtp";
        useTls = true;
        tlsImplicit = false;
      })
      (mkListener {
        cid = "listener-submission";
        name = "submission";
        bind = [ "[::]:587" ];
        protocol = "smtp";
        useTls = true;
        tlsImplicit = false;
      })
      (mkListener {
        cid = "listener-submissions";
        name = "submissions";
        bind = [ "[::]:465" ];
        protocol = "smtp";
        useTls = true;
        tlsImplicit = true;
      })
      (mkListener {
        cid = "listener-imap";
        name = "imap";
        bind = [ "[::]:143" ];
        protocol = "imap";
        useTls = true;
        tlsImplicit = false;
      })
      (mkListener {
        cid = "listener-imaps";
        name = "imaps";
        bind = [ "[::]:993" ];
        protocol = "imap";
        useTls = true;
        tlsImplicit = true;
      })
      (mkListener {
        cid = "listener-jmap";
        name = "jmap";
        bind = [ "[::1]:8080" ];
        protocol = "http";
        useTls = false;
      })
    ];

    recovery = {
      enable = false;
      adminUser = "admin";
      adminPasswordFile = config.secrets.stalwartRecoveryPassword.path;
    };

    # Plan is create-only; stays off after the initial cutover. To add or
    # change listeners, flip recovery + apply.enable on, deploy, flip back.
    apply = {
      enable = false;
      url = "http://[::1]:8080";
      adminUser = "admin";
      adminPasswordFile = config.secrets.stalwartAdminPassword.path;
    };
  };
}
