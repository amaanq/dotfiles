{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

  claude-code = pkgs.claude-code.overrideAttrs (old: {
    version = "2.1.19";
    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-2.1.19.tgz";
      hash = "sha256-K2fJf1eRAyqmtAvKBzpAtMohQ4B1icwC9yf5zEf52C8=";
    };
  });
in
{
  unfree.allowedNames = [
    "claude-code"
    "libsciter"
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
    claude-code
    pkgs.codex
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
    pkgs.gemini-cli
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
    (pkgs.files-to-prompt.overridePythonAttrs (old: {
      doCheck = false;
    }))
    pkgs.go
    pkgs.qbittorrent
    (pkgs.rustdesk.overrideAttrs (old: {
      # GCC 15 requires explicit #include <cstdint> for uint64_t
      # The webm-sys crate's bundled libwebm is missing this include
      env = old.env // {
        CXXFLAGS = "-include cstdint";
      };
    }))
    pkgs.sequoia-sq
    pkgs.signal-desktop
    pkgs.wabt
    pkgs.wasmtime
    pkgs.zed-editor
  ]
  ++ optionals (config.isLinux && config.isDesktop) [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.thunderbird
  ];
}
