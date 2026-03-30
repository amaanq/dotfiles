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
  unfree.allowedNames = [
    "megasync"
    "spotify"
  ];

  environment.systemPackages = [
    pkgs.asciinema
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
    # perl-free moreutils, which drops chronic, combine, ts, vidir, vipe, zrun (all perl)
    (pkgs.moreutils.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        rm -f $out/bin/{chronic,combine,ts,vidir,vipe,zrun}
        rm -f $out/share/man/man1/{chronic,combine,ts,vidir,vipe,zrun}.1*
      '';
      buildInputs = builtins.filter (p: !(builtins.match "perl.*" (p.pname or "") != null)) (
        old.buildInputs or [ ]
      );
      propagatedBuildInputs = builtins.filter (p: !(builtins.match "perl.*" (p.pname or "") != null)) (
        old.propagatedBuildInputs or [ ]
      );
    }))
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
    pkgs.zoxide
  ]
  ++ optionals config.isDesktop [
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
  ];
}
