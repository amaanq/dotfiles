{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;
in
{
  # Temporary fix for qtbase 6.10.0 on Darwin
  # https://github.com/NixOS/nixpkgs/pull/353633
  nixpkgs.config.packageOverrides =
    pkgs:
    lib.optionalAttrs config.isDarwin {
      qt6 = pkgs.qt6.overrideScope (
        qtfinal: qtprev: {
          qtbase = qtprev.qtbase.overrideAttrs (old: {
            cmakeFlags = old.cmakeFlags or [ ] ++ [
              "-DCMAKE_FIND_FRAMEWORK=FIRST"
            ];
          });
        }
      );
    };

  unfree.allowedNames = [
    "claude-code"
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
    pkgs.claude-code
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
    pkgs.gitui
    pkgs.graphviz
    pkgs.hyperfine
    pkgs.jc
    pkgs.moreutils
    pkgs.openssl
    pkgs.p7zip
    pkgs.pstree
    pkgs.rsync
    pkgs.sd
    pkgs.timg
    pkgs.tokei
    pkgs.unzip
    pkgs.uutils-coreutils-noprefix
    pkgs.watchman
    pkgs.xh
    pkgs.xxd
    pkgs.yazi
    pkgs.yt-dlp
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
    pkgs.sequoia-sq
    pkgs.wabt
    pkgs.wasmtime
    pkgs.zed-editor
  ]
  ++ optionals (config.isLinux && config.isDesktop) [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.spotify
    pkgs.thunderbird
  ];
}
