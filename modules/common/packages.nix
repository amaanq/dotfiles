{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  claude-code = pkgs.claude-code.overrideAttrs (
    _:
    let
      version = "2.1.23";
    in
    {
      inherit version;
      src = pkgs.fetchzip {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        hash = "sha256-Cl/lwk1ffwrc+v1ncdShjeheNnkoocmXSDUDOCRHJgQ=";
      };
    }
  );
in
{
  unfree.allowedNames = [
    "claude-code"
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
  };
}
