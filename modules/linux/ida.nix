{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    attrNames
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

  baseIdaPro = pkgs.callPackage pkgs.ida-pro {
    runfile = builtins.fetchurl {
      url = "file://${toString ./.}/modules/linux/ida-pro_91_x64linux.run";
      sha256 = "1qpr02bkq6yhd3fpzgnbzmnb4mhk1l0h3sp3m69zc3ispqi81w4g";
    };
  };

  patchedIdaPro = baseIdaPro.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ ida-patcher ];
    postInstall = (old.postInstall or "") + ''
      cd $out/opt
      ${ida-patcher}/bin/ida-patcher $out
      substituteInPlace cfg/hexrays.cfg \
        --replace "MAX_FUNCSIZE            = 64" "MAX_FUNCSIZE            = 1024"
      # Copy license to where IDA expects it
      cp *.hexlic $out/opt/ || true
    '';
  });

  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxedIdaPro = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = patchedIdaPro;
        app.binPath = "bin/ida64";

        # Enable D-Bus for GUI dialogs
        dbus.enable = true;
        dbus.policies = {
          "org.freedesktop.DBus" = "talk";
          "ca.desrt.dconf" = "talk";
        };

        flatpak.appId = "com.hexrays.IDA";

        bubblewrap = {
          # Disable network access for security
          network = false;

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
          ];

          bind.ro = [
            # Read-only access to binaries to analyze
            (sloth.concat' sloth.homeDir "/Downloads")
            # System fonts
            "/run/current-system/sw/share/fonts"
            "${pkgs.freetype}/lib"
          ];

          bind.dev = [
            # GPU access for GUI
            "/dev/dri"
          ];
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
    # Use the sandboxed version
    sandboxedIdaPro.config.env
  ];

  # Ensure the work directory exists
  systemd.tmpfiles.rules = [
    "d ${config.users.users.${user}.home}/ida-work 0700 ${user} users -"
    "d ${config.users.users.${user}.home}/.local/state/ida 0700 ${user} users -"
  ];
}
