{
  self,
  config,
  ida-nix,
  ida-tilegx,
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
    mkIf
    ;

  system = pkgs.stdenv.hostPlatform.system;
  user = head (attrNames config.users.users);

  tilegxProc = ida-tilegx.packages.${system}.default or null;

  ida-patcher = pkgs.writers.writePython3Bin "ida-patcher" {
    flakeIgnore = [
      "E1" # all indentation rules
      "E501" # line too long
    ];
  } (builtins.readFile (self + /modules/common/desktop/ida/patcher.py));

  idaSource = builtins.fetchurl {
    url = "https://cloud.amaanq.com/public.php/webdav/ida-pro_93_x64linux.run";
    sha256 = "sha256-LtQ65LuE103K5vAJkhDfqNYb/qSVL1+aB6mq4Wy3D4I=";
    name = "ida-pro_93_x64linux.run";
  };

  idaRelease = {
    version = "9.3.0.260613";
    installerName = "ida-pro_93_x64linux.run";
    installerHash = null;
    pythonPackage = "python314";
    pythonAbi = "3.14";
    systems = [ "x86_64-linux" ];
  };

  unpatchedIdaPro =
    (pkgs.mkIda {
      inherit (idaRelease) version;
      installer = idaSource;
      python = pkgs.python314;
      plugins = [ ];
      release = idaRelease;
    }).unwrapped;

  patchedIdaBase = unpatchedIdaPro.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libinput ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ ida-patcher ];
    postInstall = (old.postInstall or "") + /* sh */ ''
      cd $out/opt/ida
      ${ida-patcher}/bin/ida-patcher --oneshot
      substituteInPlace cfg/hexrays.cfg \
        --replace-fail "MAX_FUNCSIZE            = 64" "MAX_FUNCSIZE            = 1024"
    '';
    passthru = old.passthru // {
      ida = old.passthru.ida // {
        root = "${patchedIdaBase}/opt/ida";
        qtPluginPath = "${patchedIdaBase}/opt/ida/plugins:${pkgs.qt6.qtbase}/${pkgs.qt6.qtbase.qtPluginPrefix}";
        runtimeLibraryPath = lib.concatStringsSep ":" [
          old.passthru.ida.runtimeLibraryPath
          (lib.makeLibraryPath [ pkgs.libinput ])
        ];
      };
    };
  });

  idaProfile = pkgs.ida-nix.lib.compose {
    ida = patchedIdaBase;
    plugins = [
      pkgs.idaPlugins.bindiff
      pkgs.idaPlugins.ida-pro-mcp
    ];
  };

  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxedIdaPro = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = idaProfile;
        app.binPath = "bin/ida";

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
            (sloth.concat' sloth.homeDir "/.local/share/idapro")
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
            # Nix store for accessing plugins and dependencies
            "/nix/store"
            # Fonts
            "/run/current-system/sw/share/fonts"
            "${pkgs.freetype}/lib"
            # User fonts
            (sloth.concat' sloth.homeDir "/.local/share/fonts")
            # CA certificates
            "/etc/ssl/certs"
            "${pkgs.cacert}/etc/ssl/certs"
          ];

          bind.dev = [
            # GPU access for GUI
            "/dev/dri"
          ];

          env = {
            IDAUSR = sloth.concat' sloth.homeDir "/.local/share/idapro";
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
{
  config = mkIf (!config.isVirtual) {
    nixpkgs.overlays = [ ida-nix.overlays.default ];

    unfree.allowedNames = [
      "ida-pro"
      "ida-pro-unwrapped"
    ];

    environment.systemPackages = [ sandboxedIdaPro.config.env ];

    systemd.tmpfiles.rules = [
      "d ${config.users.users.${user}.home}/ida-work 0700 ${user} users -"
      "d ${config.users.users.${user}.home}/.local/state/ida 0700 ${user} users -"
    ]
    ++ lib.optionals (tilegxProc != null) [
      "d ${config.users.users.${user}.home}/.local/share/idapro/procs 0755 ${user} users -"
      "L+ ${
        config.users.users.${user}.home
      }/.local/share/idapro/procs/tilegx.so - - - - ${tilegxProc}/procs/tilegx.so"
    ];
  };
}
