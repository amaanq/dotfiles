{
  config,
  lib,
  pkgs,
  ...
}:
let
  buildPkgs = pkgs.buildPackages;

  # Unpack the scripted initrd and hand the kernel the directory to re-pack as a
  # builtin initramfs.
  initrdDir =
    buildPkgs.runCommand "varve-initrd-dir"
      {
        nativeBuildInputs = [
          buildPkgs.cpio
          buildPkgs.gzip
        ];
      }
      ''
        mkdir -p $out && cd $out
        gunzip < ${config.system.build.initialRamdisk}/initrd | cpio -idm --no-absolute-filenames

        # 7.0's early init-exec can't follow ANY symlink (-EACCES until stage-1 runs),
        # and the nixos initrd ships /init as a symlink into /nix/store. Replace it
        # with a plain copy so execve("/init") opens a regular file directly.
        if [ -L init ]; then
          tgt=$(readlink init)
          rm init
          cp "''${tgt#/}" init
          chmod +x init
        fi
      '';

  # The kernel opens /dev/console before running init, and an initramfs boot
  # doesn't auto-mount devtmpfs, so the device nodes must live in the cpio.
  initrdNodes = buildPkgs.writeText "varve-initrd-nodes" ''
    dir /dev 0755 0 0
    nod /dev/console 0600 0 0 c 5 1
    nod /dev/null    0666 0 0 c 1 3
    nod /dev/zero    0666 0 0 c 1 5
    nod /dev/tty     0666 0 0 c 5 0
    nod /dev/ttyS0   0660 0 0 c 4 64
    nod /dev/kmsg    0644 0 0 c 1 11
    nod /dev/random  0666 0 0 c 1 8
    nod /dev/urandom 0666 0 0 c 1 9
  '';

  # U-Boot corrupts a separately-loaded initrd (cvmx_bootmem carves through it),
  # so bake it into the vmlinux. Uncompressed because the pure-Clang 7.0 build
  # miscompiles zlib_inflate (a gzip initramfs unpacks to an empty rootfs).
  embeddedKernel = config.boot.kernelPackages.kernel.override (old: {
    structuredExtraConfig = (old.structuredExtraConfig or { }) // {
      BLK_DEV_INITRD = lib.kernel.yes;
      INITRAMFS_SOURCE = lib.kernel.freeform "${initrdNodes} ${initrdDir}";
      INITRAMFS_COMPRESSION_NONE = lib.kernel.yes;
    };
  });
in
{
  system.build.tftpKernel = embeddedKernel;
}
