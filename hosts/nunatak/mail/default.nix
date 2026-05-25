{
  self,
  config,
  lib,
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
  # Rampart identity — separated from amaanq's mail at the IP/PTR/EHLO/cert
  # level so DNS tracing of pool domains never leads back to amaanq.com.
  rampartZone = "rampart.email";
  rampartHost = "mx.${rampartZone}";
  rampartAcmeRoot = "/var/lib/acme/${rampartZone}";

  # amaanq IPs the existing identity binds inbound to. Pulled here to keep
  # the listener-smtp bind list and the per-IP hostname expression in sync.
  amaanqInboundV4 = "152.53.83.122";
  amaanqInboundV6 = "2a0a:4cc0:2000:3f59::1";
  rampartInboundV4 = "152.53.31.156";

  # Create a NetworkListener (full body, server assigns id). `cid` is a
  # temp-create-id usable as `#<cid>` from later ops in the same plan.
  mkCreateListener =
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
        inherit
          name
          protocol
          useTls
          tlsImplicit
          ;
        bind = lib.listToAttrs (
          map (addr: {
            name = addr;
            value = true;
          }) bind
        );
      };
    };

  # Patch an existing NetworkListener by JMAP id (cli expects partial patch).
  mkUpdateListener =
    {
      id,
      patch,
    }:
    {
      "@type" = "update";
      object = "NetworkListener";
      inherit id;
      value = patch;
    };

  # nginx → stalwart HTTP proxy helper.
  mkProxy = path: extra: {
    proxyPass = "http://[::1]:8080${path}";
    extraConfig = ''
      proxy_set_header Host mail.${domain};
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    ''
    + extra;
  };

  # JMAP autodiscovery for secondary mail-using domains.
  autodiscoveryLocations = {
    "/.well-known/jmap" = mkProxy "/.well-known/jmap" "";
    "/jmap" = mkProxy "/jmap" "client_max_body_size 50M;\n";
  };

  # mail.amaanq.com proxies the entire stalwart surface.
  fullMailLocations = {
    "/" = mkProxy "" "client_max_body_size 50M;\n";
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
  security.acme.certs.${rampartZone}.reloadServices = [ "stalwart.service" ];

  services.nginx.virtualHosts =
    lib.genAttrs domains (
      _: config.services.nginx.sslTemplate // { locations = autodiscoveryLocations; }
    )
    // {
      "mail.${domain}" = config.services.nginx.sslTemplate // {
        locations = fullMailLocations;
      };
    };

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

    # Base listeners were seeded during the 0.16 cutover and live in the DB;
    # we only patch listener-smtp's bind and add rampart-specific objects.
    plan = [
      # Constrain listener-smtp to amaanq IPs so listener-smtp-rampart on
      # 152.53.31.156:25 doesn't fight it. `id` is JMAP-assigned at create.
      (mkUpdateListener {
        id = "ipkm9jiqacaa";
        patch.bind = lib.listToAttrs (
          map
            (addr: {
              name = addr;
              value = true;
            })
            [
              "${amaanqInboundV4}:25"
              "[${amaanqInboundV6}]:25"
            ]
        );
      })

      # rampart inbound MX: separate IP/cert, selected by SNI on STARTTLS.
      (mkCreateListener {
        cid = "listener-smtp-rampart";
        name = "smtp-rampart";
        bind = [ "${rampartInboundV4}:25" ];
        protocol = "smtp";
        useTls = true;
        tlsImplicit = false;
      })

      # Certificate for ${rampartHost}; stalwart auto-populates metadata.
      {
        "@type" = "create";
        object = "Certificate";
        value.cert-rampart = {
          certificate = {
            "@type" = "File";
            filePath = "${rampartAcmeRoot}/fullchain.pem";
          };
          privateKey = {
            "@type" = "File";
            filePath = "${rampartAcmeRoot}/key.pem";
          };
        };
      }

      # MtaStageConnect: per-local_ip hostname/greeting/authserv-id branch.
      {
        "@type" = "update";
        object = "MtaStageConnect";
        value = {
          hostname = {
            match = {
              "0" = {
                "if" = "local_ip == '${rampartInboundV4}'";
                "then" = "'${rampartHost}'";
              };
            };
            "else" = "'mail.${domain}'";
          };
          smtpGreeting = {
            match = {
              "0" = {
                "if" = "local_ip == '${rampartInboundV4}'";
                "then" = "'${rampartHost} ESMTP service ready'";
              };
            };
            "else" = "'mail.${domain} ESMTP service ready'";
          };
        };
      }

      # Outbound for amaanq-sender mail; named so the outbound strategy
      # below can branch on it.
      {
        "@type" = "create";
        object = "MtaConnectionStrategy";
        value.conn-amaanq = {
          name = "conn-amaanq";
          ehloHostname = "mail.${domain}";
          sourceIps = {
            "0" = {
              sourceIp = amaanqInboundV4;
              ehloHostname = "mail.${domain}";
            };
            "1" = {
              sourceIp = amaanqInboundV6;
              ehloHostname = "mail.${domain}";
            };
          };
        };
      }

      # Outbound for rampart-sender mail (alias-domain MAIL FROM).
      {
        "@type" = "create";
        object = "MtaConnectionStrategy";
        value.conn-rampart = {
          name = "conn-rampart";
          ehloHostname = rampartHost;
          sourceIps = {
            "0" = {
              sourceIp = rampartInboundV4;
              ehloHostname = rampartHost;
            };
          };
        };
      }

      # Outbound routing: amaanq sender_domain → conn-amaanq, else
      # conn-rampart. Forgotten domains leak as rampart, not amaanq.
      {
        "@type" = "update";
        object = "MtaOutboundStrategy";
        value = {
          connection = {
            match = {
              "0" = {
                "if" = lib.concatMapStringsSep " || " (d: "sender_domain == '${d}'") domains;
                "then" = "'conn-amaanq'";
              };
            };
            "else" = "'conn-rampart'";
          };
        };
      }
    ];

    recovery = {
      enable = false;
      adminUser = "admin";
      adminPasswordFile = config.secrets.stalwartRecoveryPassword.path;
    };

    # apply isn't idempotent on create-on-existing; stays off after cutover.
    # Flip on + `systemctl start stalwart-apply` once when seeding new objects.
    apply = {
      enable = false;
      url = "http://[::1]:8080";
      adminUser = "admin";
      adminPasswordFile = config.secrets.stalwartAdminPassword.path;
    };
  };
}
