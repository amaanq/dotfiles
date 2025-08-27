{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) optionals;
in
{
  unfree.allowedNames = [
    "claude-code"
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
    pkgs.claude-code
    pkgs.cowsay
    pkgs.curlHTTP3
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
    pkgs.raycast
  ]
  ++ optionals config.isDesktop [
    pkgs.element-desktop
    pkgs.files-to-prompt
    pkgs.go
    # pkgs.qbittorrent
    pkgs.sequoia-sq
    pkgs.telegram-desktop
  ]
  ++ optionals (config.isLinux && config.isDesktop) [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.pavucontrol
    pkgs.spotify
    pkgs.thunderbird
    inputs.claude-desktop.packages.${pkgs.system}.claude-desktop
  ];
}
