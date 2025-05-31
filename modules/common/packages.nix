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
          dust
          doggo
          eza
          fastfetch
          fd
          file
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
          xxd
          yazi
          yt-dlp
          ;

        nil = inputs.nil.packages.${pkgs.system}.default;

        # Shell and terminal
        inherit (pkgs)
          keychain
          dwt1-shell-color-scripts
          ;
      }
      // optionalAttrs config.isLinux {
        inherit (pkgs)
          traceroute
          usbutils
          strace
          ;
      }
      // optionalAttrs config.isDesktop {
        inherit (pkgs)
          element-desktop
          files-to-prompt
          obs-studio
          pavucontrol
          sequoia-sq
          spotify
          telegram-desktop
          ;
      };
}
