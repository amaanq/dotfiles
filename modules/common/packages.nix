{
  config,
  lib,
  pkgs,
  age-plugin-fido2-hmac,
  nixtopsy,
  ...
}:
let
  inherit (lib) optionals;
in
{
  unfree.allowedNames = [
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.curl
    pkgs.dig
    pkgs.dust
    pkgs.fd
    pkgs.file
    pkgs.hyperfine
    pkgs.jq
    pkgs.openssl
    pkgs.p7zip
    pkgs.pstree
    pkgs.rsync
    pkgs.sd
    pkgs.tree
    pkgs.unzip
    pkgs.uutils-coreutils-noprefix
    pkgs.xh
    pkgs.xxd
    pkgs.zoxide
  ]
  ++ optionals config.isDesktop [
    age-plugin-fido2-hmac.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.asciinema
    pkgs.dwt1-shell-color-scripts
    pkgs.graphviz
    pkgs.jc
    nixtopsy.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.rbw
    pkgs.tokei
    pkgs.watchman
  ]
  ++ optionals config.isLinux [
    pkgs.strace
    pkgs.traceroute
    pkgs.usbutils
  ]
  ++ optionals config.isDarwin [
    pkgs.iina
    pkgs.maccy
  ];
}
