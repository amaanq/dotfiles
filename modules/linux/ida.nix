{
  config,
  lib,
  nixpak,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    enabled
    head
    merge
    mkIf
    ;

  user = head (attrNames config.users.users);

  ida-patcher = pkgs.writers.writePython3Bin "ida-patcher" {
    flakeIgnore = [
      "E501" # line too long (more than 79 characters)
    ];
  } (builtins.readFile ./patch.py);

  baseIdaPro = pkgs.ida-pro.override {
    runfile = builtins.fetchurl {
      url = "file://${toString ./.}/ida-pro_92_x64linux.run";
      sha256 = "1qass0401igrfn14sfrvjfyz668npx586x59yaa4zf3jx650zpda";
    };
  };

  patchedIdaPro = baseIdaPro.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ ida-patcher ];
    postInstall = (old.postInstall or "") + ''
      cd $out/opt
      ${ida-patcher}/bin/ida-patcher $out
      substituteInPlace cfg/hexrays.cfg \
        --replace "MAX_FUNCSIZE            = 64" "MAX_FUNCSIZE            = 1024"
      cp *.hexlic $out/opt/ || true
    '';
  });

  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxedIdaPro = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = patchedIdaPro;
        app.binPath = "opt/ida";

        # D-Bus for GUI dialogs?
        dbus = enabled {
          policies = {
            "org.freedesktop.DBus" = "talk";
            "ca.desrt.dconf" = "talk";
          };
        };

        flatpak.appId = "com.hexrays.IDA";

        bubblewrap = {
          network = true;

          bind.rw = [
            # IDA config directory
            [
              (sloth.concat' sloth.homeDir "/.local/state/ida")
              (sloth.concat' sloth.homeDir "/.idapro")
            ]
            # Runtime directory for temp files
            (sloth.env "XDG_RUNTIME_DIR")
            # Work directory for analysis
            (sloth.concat' sloth.homeDir "/ida-work")
            (sloth.concat' sloth.homeDir "/projects")
            # Temp directory for BinDiff exports
            "/tmp"
            # Downloads for reading/writing IDB files
            (sloth.concat' sloth.homeDir "/Downloads")
          ];

          bind.ro = [
            # TODO: rw dir for databases
            # Nix store for accessing plugins and dependencies
            "/nix/store"
            # System binaries (for BinDiff spawning IDA)
            "/run/current-system/sw/bin"
            # Fonts
            "/run/current-system/sw/share/fonts"
            "${pkgs.freetype}/lib"
            # User fonts (TX-02, Berkeley Mono, etc.)
            (sloth.concat' sloth.homeDir "/.local/share/fonts")
            # CA certificates
            "/etc/ssl/certs"
            "${pkgs.cacert}/etc/ssl/certs"
            # BinDiff/BinExport plugins (for spawned IDA instances)
            "/run/current-system/sw/share/bindiff"
          ];

          bind.dev = [
            # GPU access for GUI
            "/dev/dri"
          ];

          env = {
            LUMINA_HOST = "nunatak";
            LUMINA_PORT = "443";
            LUMINA_TLS = "YES";
            SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
            NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          };
        };
      };
  };
in
merge
<| mkIf (config.isDesktop && !config.isVirtual) {
  unfree.allowedNames = [
    "ida-pro"
  ];

  environment.systemPackages = [
    sandboxedIdaPro.config.env
    (pkgs.runCommand "ida64-compat" { } ''
      mkdir -p $out/bin
      ln -s ${sandboxedIdaPro.config.env}/bin/ida $out/bin/ida64
    '')
  ];

  programs.bindiff = enabled {
    enableIdaPlugin = true;
  };

  systemd.tmpfiles.rules = [
    "d ${config.users.users.${user}.home}/ida-work 0700 ${user} users -"
    "d ${config.users.users.${user}.home}/.local/state/ida 0700 ${user} users -"
  ]
  ++ lib.optional (
    config.programs.bindiff.enable && config.programs.bindiff.enableIdaPlugin
  ) "L+ ${patchedIdaPro}/opt/ida64 - - - - /run/current-system/sw/bin/ida64";
}
