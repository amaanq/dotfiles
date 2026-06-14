{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.stalwart;
  jsonFormat = pkgs.formats.json { };

  configFile = jsonFormat.generate "stalwart-config.json" cfg.dataStore;

  # stalwart-cli apply requires NDJSON (rejects JSON arrays).
  planNDJSON = pkgs.writeText "stalwart-plan.ndjson" (
    lib.concatMapStringsSep "\n" (op: builtins.toJSON op) cfg.plan
    + lib.optionalString (cfg.plan != [ ]) "\n"
  );

  knownUserNames = [
    "stalwart"
    "stalwart-mail"
  ];
in
{
  disabledModules = [ "services/mail/stalwart.nix" ];

  options.services.stalwart = {
    enable = lib.mkEnableOption "the Stalwart all-in-one mail and collaboration server (v0.16+)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.stalwart_0_16;
      defaultText = lib.literalExpression "pkgs.stalwart_0_16";
      description = "The stalwart server package. Defaults to the 0.16-pinned overlay attribute.";
    };

    cliPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.stalwart-cli_1_0;
      defaultText = lib.literalExpression "pkgs.stalwart-cli_1_0";
      description = "The stalwart-cli package used by the apply unit. Must be 1.x (separate repo).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "stalwart-mail";
      description = ''
        Unix user the server runs as. Default kept at "stalwart-mail" so existing
        deployments migrating from the 0.15 nixpkgs module don't have to chown
        the data directory in the same change as the schema migration.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "stalwart-mail";
      description = "Unix group the server runs as. See `user` for naming rationale.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/stalwart-mail";
      description = ''
        Persistent data directory. Embedded backends (RocksDB, SQLite, filesystem
        blobs) write here. PostgreSQL/MySQL deployments still need this for
        bootstrap state and credential staging.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open the TCP ports listed in `firewallPorts`. The 0.15 module derived
        ports from the listener attrset, but listeners now live in the database
        plan and are not visible at evaluation time, so the port list is
        explicit.
      '';
    };

    firewallPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        25
        80
        143
        443
        465
        587
        993
        4190
      ];
      description = ''
        TCP ports to open when `openFirewall` is true. Default covers SMTP
        (25), submission (587 STARTTLS, 465 implicit TLS), IMAP (143/993),
        ManageSieve (4190), and HTTP/HTTPS (80/443) for ACME and JMAP.
      '';
    };

    dataStore = lib.mkOption {
      inherit (jsonFormat) type;
      description = ''
        DataStore object written verbatim to config.json. The top-level "@type"
        discriminator selects RocksDb, Sqlite, FoundationDb, PostgreSql, or
        MySql. See the migration script (resources/scripts/migrate_v016.py in
        the stalwart source) for the exact key shape per backend.
      '';
      example = lib.literalExpression ''
        {
          "@type" = "PostgreSql";
          host = "localhost";
          port = 5432;
          database = "stalwart-mail";
          authUsername = "stalwart-mail";
          authSecret = { "@type" = "None"; };
        }
      '';
    };

    plan = lib.mkOption {
      type = lib.types.listOf jsonFormat.type;
      default = [ ];
      description = ''
        Declarative plan reconciled by `stalwart-cli apply` after the server
        starts. Each list element is one apply operation:

          { "@type" = "create"; object = "Domain"; value = { … }; }
          { "@type" = "update"; object = "SystemSettings"; value = { … }; }
          { "@type" = "destroy"; object = "Domain"; value = { … }; }

        The list is rendered to NDJSON (one op per line) at evaluation time
        and exposed as `/etc/stalwart/plan.ndjson`. References between created
        objects use "#<create-id>" syntax — the create-id is the attribute name
        under `value`.
      '';
      example = lib.literalExpression ''
        [
          {
            "@type" = "create";
            object = "Domain";
            value.create-amaanq = { name = "amaanq.com"; };
          }
          {
            "@type" = "update";
            object = "SystemSettings";
            value = {
              defaultDomainId = "#create-amaanq";
              defaultHostname = "mail.amaanq.com";
            };
          }
        ]
      '';
    };

    credentials = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Files exposed to the stalwart unit via systemd LoadCredential. Inside
        config.json they can be referenced as
        `%{file:/run/credentials/stalwart.service/<name>}%` — the server
        expands these placeholders at parse time. Account/admin secrets pushed
        via the apply plan must be substituted on the cli side instead, since
        the placeholder syntax is not honoured by JMAP requests.
      '';
      example = lib.literalExpression ''
        {
          dkim_amaanq = config.secrets.stalwartDkimKey.path;
        }
      '';
    };

    recovery = {
      enable = lib.mkEnableOption ''
        recovery mode for a one-shot migration boot. When true, the server is
        started with STALWART_RECOVERY_MODE=1, which wipes the settings and
        directory tables and brings up only the management endpoint on port
        8080. The apply unit is skipped while recovery mode is active so the
        operator can replay the python-script-generated export.json by hand.
        Flip back to false after the migration completes
      '';

      adminUser = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Username for the temporary recovery admin (STALWART_RECOVERY_ADMIN).";
      };

      adminPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          File containing the recovery admin password. Required when
          `recovery.enable` is true. Loaded via systemd LoadCredential and
          combined with `recovery.adminUser` into the
          STALWART_RECOVERY_ADMIN environment variable.
        '';
      };
    };

    apply = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to run `stalwart-cli apply` against the rendered plan after
          the server starts. The apply unit is automatically inhibited while
          `recovery.enable` is true.
        '';
      };

      url = lib.mkOption {
        type = lib.types.str;
        default = "http://[::1]:8080";
        description = ''
          Base URL the apply unit talks to. Defaults to the loopback admin
          listener; override if the management endpoint is published on a
          different interface or port.
        '';
      };

      adminUser = lib.mkOption {
        type = lib.types.str;
        default = "admin";
        description = "Admin username the apply unit authenticates with.";
      };

      adminPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          File containing the admin password the apply unit will use. May be
          the same file as `recovery.adminPasswordFile` immediately after
          migration, then rotated to a real DB-backed admin once one is
          created.
        '';
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra flags appended to `stalwart-cli apply`.";
        example = [ "--continue-on-error" ];
      };

      preStart = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Shell snippet executed by the apply unit before `stalwart-cli apply`
          runs. Intended for plan preprocessing such as substituting credential
          values into placeholder strings. The rendered plan is exposed at
          `$PLAN_FILE` (path inside the unit's RuntimeDirectory) and the
          original immutable copy at `$PLAN_SRC`. The snippet may rewrite
          `$PLAN_FILE` in place.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.recovery.enable -> cfg.recovery.adminPasswordFile != null;
        message = "services.stalwart.recovery.enable requires recovery.adminPasswordFile to be set.";
      }
    ];

    users.groups = lib.mkIf (lib.elem cfg.group knownUserNames) {
      ${cfg.group} = { };
    };

    users.users = lib.mkIf (lib.elem cfg.user knownUserNames) {
      ${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) group;
        home = cfg.dataDir;
      };
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    environment.systemPackages = [
      cfg.package
      cfg.cliPackage
    ];

    environment.etc."stalwart/plan.ndjson".source = planNDJSON;
    environment.etc."stalwart/config.json".source = configFile;

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = cfg.firewallPorts;
    };

    systemd.services.stalwart = {
      description = "Stalwart Mail Server";
      wantedBy = [ "multi-user.target" ];
      after = [
        "local-fs.target"
        "network.target"
      ]
      ++ lib.optional config.services.postgresql.enable "postgresql.service";
      requires = lib.optional config.services.postgresql.enable "postgresql.service";

      # Reconcile the declarative plan on every (re)start, not just at boot.
      wants = lib.optional (cfg.apply.enable && !cfg.recovery.enable) "stalwart-apply.service";

      environment = lib.optionalAttrs cfg.recovery.enable {
        STALWART_RECOVERY_MODE = "1";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        RuntimeDirectory = "stalwart";
        RuntimeDirectoryMode = "0700";

        ExecStart = "${cfg.package}/bin/stalwart --config=${configFile}";

        # Splice the recovery credential into a transient EnvironmentFile so
        # STALWART_RECOVERY_ADMIN never lands in the nix store.
        ExecStartPre = lib.mkIf cfg.recovery.enable [
          (pkgs.writeShellScript "stalwart-recovery-env" /* sh */ ''
            set -eu
            umask 0077
            pw=$(cat "$CREDENTIALS_DIRECTORY/recovery_admin")
            printf 'STALWART_RECOVERY_ADMIN=%s:%s\n' \
              ${lib.escapeShellArg cfg.recovery.adminUser} "$pw" \
              > "$RUNTIME_DIRECTORY/recovery-admin.env"
          '')
        ];

        EnvironmentFile = lib.mkIf cfg.recovery.enable [
          "-/run/stalwart/recovery-admin.env"
        ];

        LoadCredential =
          lib.mapAttrsToList (k: v: "${k}:${toString v}") cfg.credentials
          ++ lib.optional cfg.recovery.enable "recovery_admin:${toString cfg.recovery.adminPasswordFile}";

        LimitNOFILE = 65536;
        KillMode = "process";
        KillSignal = "SIGINT";
        Restart = "on-failure";
        RestartSec = 5;
        SyslogIdentifier = "stalwart";

        ReadWritePaths = [ cfg.dataDir ];

        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
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

    systemd.services.stalwart-apply = lib.mkIf (cfg.apply.enable && !cfg.recovery.enable) {
      description = "Reconcile Stalwart declarative plan";
      after = [ "stalwart.service" ];

      # Driven by stalwart.service's wants= so `systemctl restart stalwart`
      # re-fires the oneshot.
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        RuntimeDirectory = "stalwart-apply";
        RuntimeDirectoryMode = "0700";

        LoadCredential = lib.optional (
          cfg.apply.adminPasswordFile != null
        ) "apply_admin:${toString cfg.apply.adminPasswordFile}";

        ExecStart = pkgs.writeShellScript "stalwart-apply" /* sh */ ''
          set -eu

          PLAN_SRC=${planNDJSON}
          PLAN_FILE=$RUNTIME_DIRECTORY/plan.ndjson
          export PLAN_SRC PLAN_FILE
          install -m 0600 "$PLAN_SRC" "$PLAN_FILE"

          ${cfg.apply.preStart}

          # cli treats an empty plan as an error.
          if [ ! -s "$PLAN_FILE" ]; then
            echo "stalwart-apply: empty plan, nothing to do" >&2
            exit 0
          fi

          # Wait for the management endpoint. /.well-known/jmap returns 200
          # or 401 once bootstrap finishes; "/" 404s and would stall curl -f.
          for _ in $(seq 1 60); do
            code=$(${pkgs.curl}/bin/curl -sS -o /dev/null -w '%{http_code}' \
                     --connect-timeout 1 \
                     ${lib.escapeShellArg cfg.apply.url}/.well-known/jmap || true)
            case "$code" in
              2*|3*|4*) break ;;
            esac
            sleep 1
          done

          export STALWART_URL=${lib.escapeShellArg cfg.apply.url}
          export STALWART_USER=${lib.escapeShellArg cfg.apply.adminUser}
          ${lib.optionalString (cfg.apply.adminPasswordFile != null) ''
            STALWART_PASSWORD=$(cat "$CREDENTIALS_DIRECTORY/apply_admin")
            export STALWART_PASSWORD
          ''}

          exec ${cfg.cliPackage}/bin/stalwart-cli apply \
            --file "$PLAN_FILE" \
            ${lib.escapeShellArgs cfg.apply.extraArgs}
        '';
      };
    };
  };

  meta.maintainers = [ ];
}
