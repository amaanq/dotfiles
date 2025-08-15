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
    pkgs.cowsay
    pkgs.curlHTTP3
    pkgs.dig
    pkgs.doggo
    pkgs.dust
    pkgs.dwt1-shell-color-scripts
    pkgs.eza
    pkgs.fd
    pkgs.file
    pkgs.gitui
    pkgs.hyperfine
    pkgs.jc
    pkgs.moreutils
    pkgs.openssl
    pkgs.p7zip
    pkgs.pstree
    pkgs.rsync
    pkgs.sd
    pkgs.tokei
    pkgs.unzip
    pkgs.uutils-coreutils-noprefix
    pkgs.watchman
    pkgs.xh
    pkgs.xxd
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
  # Server or Desktop, as long as it isn't limited on space
  ++ optionals (!config.isConstrained) [
    pkgs.claude-code
    pkgs.fastfetch
    pkgs.timg
    pkgs.yazi
    pkgs.yt-dlp
  ]
  ++ optionals config.isDesktop [
    pkgs.element-desktop
    pkgs.files-to-prompt
    pkgs.go
    pkgs.qbittorrent
    pkgs.sequoia-sq
    pkgs.spotify
    pkgs.telegram-desktop
  ]
  ++ optionals (config.isLinux && config.isDesktop) [
    pkgs.obs-studio
    pkgs.megasync
    pkgs.pavucontrol
    pkgs.thunderbird
    inputs.claude-desktop.packages.${pkgs.system}.claude-desktop
  ]
  ++ optionals config.isConstrained [
    (pkgs.yazi.override {
      # Yazi pulls in ffmpeg, which I'd rather not for constrained servers.
      optionalDeps = [
        pkgs.fd
        pkgs.ripgrep
      ];
    })
  ];
}
