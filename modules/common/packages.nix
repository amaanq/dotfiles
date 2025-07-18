{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) attrValues optionalAttrs;
in
{
  unfree.allowedNames = [
    "claude-code"
    "megasync"
    "spotify"
  ];

  environment.systemPackages =
    attrValues
    <|
      {
        # Core utilities
        inherit (pkgs)
          aider-chat
          asciinema
          claude-code
          cowsay
          curlHTTP3
          dig
          doggo
          dust
          dwt1-shell-color-scripts
          eza
          fastfetch
          fd
          file
          gitui
          hyperfine
          moreutils
          nixfmt-rfc-style
          openssl
          p7zip
          pstree
          rsync
          timg
          tokei
          unzip
          uutils-coreutils-noprefix
          watchman
          xh
          xxd
          yazi
          yt-dlp
          ;

        nil = inputs.nil.packages.${pkgs.system}.default;
      }
      // optionalAttrs config.isLinux {
        inherit (pkgs)
          strace
          traceroute
          usbutils
          ;
      }
      // optionalAttrs config.isDarwin {
        inherit (pkgs)
          iina
          maccy
          raycast
          ;
      }
      // optionalAttrs config.isDesktop {
        inherit (pkgs)
          element-desktop
          files-to-prompt
          qbittorrent
          sequoia-sq
          spotify
          telegram-desktop
          ;
      }
      // optionalAttrs (config.isLinux && config.isDesktop) {
        inherit (pkgs)
          obs-studio
          megasync
          pavucontrol
          ;
      };
}
