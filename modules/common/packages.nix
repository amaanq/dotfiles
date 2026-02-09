{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  claude-code =
    let
      version = "2.1.37";
      baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}";
      sources = {
        x86_64-linux = {
          url = "${baseUrl}/linux-x64/claude";
          hash = "sha256-+Wek0G4WoyQ2tjKeLb7UWan6TTTwdjWh+ycbdPcGyR8=";
        };
        aarch64-linux = {
          url = "${baseUrl}/linux-arm64/claude";
          hash = "sha256-1yXMcwYPQAp6wDp2mWk5fa7J1BHb1bHHux+mBCe/ZX4=";
        };
        aarch64-darwin = {
          url = "${baseUrl}/darwin-arm64/claude";
          hash = "sha256-AO0Qr7elYkQHc94xKEVozpwzOF1506kSoSryYq79Ew4=";
        };
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = "claude-code";
      inherit version;
      src = pkgs.fetchurl sources.${pkgs.stdenv.hostPlatform.system};
      dontUnpack = true;
      dontStrip = true;
      nativeBuildInputs = [
        pkgs.makeBinaryWrapper
      ]
      ++ optionals pkgs.stdenv.hostPlatform.isElf [ pkgs.autoPatchelfHook ];
      installPhase = ''
        install -Dm755 $src $out/bin/.claude-unwrapped
        makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
          --set DISABLE_AUTOUPDATER 1 \
          --set DISABLE_INSTALLATION_CHECKS 1 \
          --set USE_BUILTIN_RIPGREP 0 \
          --prefix PATH : ${
            lib.makeBinPath (
              [
                pkgs.procps
                pkgs.ripgrep
              ]
              ++ optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.bubblewrap
                pkgs.socat
              ]
            )
          }
      '';
      meta = {
        mainProgram = "claude";
        platforms = builtins.attrNames sources;
      };
    };
in
{
  unfree.allowedNames = [
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
    claude-code
    pkgs.cowsay
    pkgs.curl
    pkgs.dig
    pkgs.doggo
    pkgs.dust
    pkgs.dwt1-shell-color-scripts
    pkgs.eza
    pkgs.fastfetch
    pkgs.fd
    pkgs.file
    pkgs.gitui
    pkgs.graphviz
    pkgs.hyperfine
    pkgs.jc
    pkgs.jq
    pkgs.moreutils
    pkgs.opencode
    pkgs.openssl
    pkgs.p7zip
    pkgs.pstree
    pkgs.rbw
    pkgs.rsync
    pkgs.sd
    pkgs.timg
    pkgs.tokei
    pkgs.unzip
    pkgs.uutils-coreutils-noprefix
    pkgs.watchman
    pkgs.xh
    pkgs.xxd
    pkgs.yt-dlp
    pkgs.zoxide
  ]
  ++ optionals config.isLinux [
    pkgs.strace
    pkgs.traceroute
    pkgs.usbutils
  ]
  ++ optionals config.isDarwin [
    pkgs.iina
    pkgs.maccy
  ]
  ++ optionals config.isDesktop [
    pkgs.files-to-prompt
    pkgs.go
    pkgs.qbittorrent
    pkgs.sequoia-sq
    pkgs.signal-desktop
    pkgs.wabt
    pkgs.wasmtime
  ]
  ++ optionals (config.isLinux && config.isDesktop) [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.thunderbird
  ];

  environment.variables = {
    CLAUDE_CONFIG_DIR = "$XDG_CONFIG_HOME/claude";
    GOPATH = "$XDG_DATA_HOME/go";
    GOTELEMETRY = "off";
  };
}
