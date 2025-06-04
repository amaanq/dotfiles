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
          doggo
          dust
          dwt1-shell-color-scripts
          eza
          fastfetch
          fd
          file
          hyperfine
          keychain
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
          megasync
          qbittorrent
          sequoia-sq
          spotify
          telegram-desktop
          ;
      }
      // optionalAttrs (config.isLinux && config.isDesktop) {
        inherit (pkgs)
          obs-studio
          pavucontrol
          ;
      };
}
