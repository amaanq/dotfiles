{ lib, pkgs, ... }:
let
  inherit (lib)
    const
    enabled
    flip
    genAttrs
    ;
in
{
  environment.etc."xdg/menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <DefaultMergeDirs/>
      <Include>
        <All/>
      </Include>
    </Menu>
  '';

  xdg.mime.defaultApplications =
    flip genAttrs (const "org.kde.dolphin.desktop") [
      "inode/directory"
    ]
    // flip genAttrs (const "org.kde.ark.desktop") [
      # libarchive (read-write)
      "application/x-tar"
      "application/x-compressed-tar"
      "application/x-bzip-compressed-tar"
      "application/x-bzip2-compressed-tar"
      "application/x-tarz"
      "application/x-xz-compressed-tar"
      "application/x-lzma-compressed-tar"
      "application/x-lzip-compressed-tar"
      "application/x-tzo"
      "application/x-lrzip-compressed-tar"
      "application/x-lz4-compressed-tar"
      "application/x-zstd-compressed-tar"
      "application/x-7z-compressed"

      # libarchive (read-only)
      "application/gzip"
      "application/zlib"
      "application/zstd"
      "application/x-bzip"
      "application/x-bzip2"
      "application/x-lzma"
      "application/x-xz"
      "application/x-lz4"
      "application/x-lzip"
      "application/x-lrzip"
      "application/x-lzop"
      "application/x-compress"
      "application/x-bcpio"
      "application/x-cpio"
      "application/x-cpio-compressed"
      "application/x-sv4cpio"
      "application/x-sv4crc"
      "application/x-archive"
      "application/x-cd-image"
      "application/vnd.efi.iso"
      "application/x-iso9660-appimage"
      "application/x-deb"
      "application/vnd.debian.binary-package"
      "application/x-rpm"
      "application/x-source-rpm"
      "application/vnd.ms-cab-compressed"
      "application/x-xar"

      # zip
      "application/zip"
      "application/x-java-archive"

      # rar
      "application/vnd.rar"

      # arj
      "application/arj"
      "application/x-arj"

      # unarchiver
      "application/x-lha"
      "application/x-stuffit"
    ];

  services.udisks2 = enabled {
    mountOnMedia = true;
  };
  services.upower = enabled;

  systemd.user.services.udiskie = {
    description = "udiskie mount daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --no-tray";
      Restart = "on-failure";
    };
  };

  environment.systemPackages = [
    pkgs.ffmpegthumbnailer
    pkgs.udiskie
  ]
  ++ (with pkgs.kdePackages; [
    dolphin
    dolphin-plugins
    ark
    kio
    kio-extras
    kio-fuse
    kservice
    kde-cli-tools
    kimageformats
    ffmpegthumbs
    kdegraphics-thumbnailers
  ]);
}
