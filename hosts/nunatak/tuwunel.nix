{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      # The actual bug is in RocksDB, not bcachefs: `PosixHelper::GetLogicalBlockSizeOfFd`
      # reads `/sys/dev/block/<maj>:<min>/queue/logical_block_size` — the
      # underlying *block device's* sector size — and uses that as the DIO
      # alignment. For filesystems whose FS-level block_size exceeds the
      # device sector (bcachefs, ZFS, btrfs RAID), RocksDB then issues
      # 512-byte- or 4 KiB-aligned `pwrite`s against an FS that needs e.g.
      # 16 KiB alignment, kernel returns EINVAL on the first SST flush, the
      # whole DB open aborts. Linux 6.1+ has `statx(STATX_DIOALIGN)` which
      # returns the authoritative DIO alignment for any FS — patch RocksDB
      # to use that first and fall back to the existing sysfs walk.
      # Tracked upstream as facebook/rocksdb#14671.
      #
      # nixpkgs' matrix-tuwunel package.nix builds its own `rocksdb'` from
      # the matrix-construct fork and explicitly sets `patches = [ ]` in
      # the inner overrideAttrs, so a vanilla `pkgs.rocksdb` overlay gets
      # wiped. Reconstruct that derivation here with our patch added, then
      # point matrix-tuwunel's ROCKSDB_{INCLUDE,LIB}_DIR at it.
      matrix-tuwunel =
        let
          rust-jemalloc-sys' = prev.rust-jemalloc-sys.override {
            unprefixed = !prev.stdenv.hostPlatform.isDarwin;
          };
          rocksdbTuwunel =
            (prev.rocksdb.override {
              inherit (prev) liburing;
              enableLiburing = prev.stdenv.hostPlatform.isLinux;
              enableJemalloc = !prev.stdenv.hostPlatform.isDarwin;
              jemalloc = rust-jemalloc-sys';
            }).overrideAttrs
              (old: {
                src = prev.fetchFromGitHub {
                  owner = "matrix-construct";
                  repo = "rocksdb";
                  rev = "9a3a213b55df0b11408102c899a940675c0d90e4";
                  hash = "sha256-aOV/jJjRjNJ3hrRqhCsXlIz05NvEhDF/j5Q5UOQuvp8=";
                };
                version = "tuwunel-changes";
                patches = [
                  (prev.fetchpatch {
                    name = "rocksdb-statx-dioalign-pr14671.patch";
                    url = "https://github.com/facebook/rocksdb/pull/14671.patch";
                    # matrix-construct fork has drifted on env_test.cc
                    excludes = [ "env/env_test.cc" ];
                    hash = "sha256-NaDrJjB2uwTLkbporTO11HdxOOHdtsZNwKNWHj6yDWs=";
                  })
                ];
                postPatch = "";
                cmakeFlags =
                  prev.lib.subtractLists [
                    "-DWITH_SNAPPY=1"
                    "-DZLIB=1"
                    "-DWITH_ZLIB=1"
                    "-DWITH_CORE_TOOLS=1"
                    "-DWITH_TESTS=1"
                    "-DUSE_RTTI=1"
                    "-DFORCE_SSE42=1"
                    "-DPORTABLE=1"
                  ] old.cmakeFlags
                  ++ [
                    "-DWITH_SNAPPY=0"
                    "-DZLIB=0"
                    "-DWITH_ZLIB=0"
                    "-DWITH_CORE_TOOLS=0"
                    "-DWITH_TRACE_TOOLS=0"
                    "-DWITH_TESTS=0"
                    "-DUSE_RTTI=0"
                  ];
                outputs = [ "out" ];
                preInstall = "";
              });
        in
        prev.matrix-tuwunel.overrideAttrs (old: {
          env = (old.env or { }) // {
            ROCKSDB_INCLUDE_DIR = "${rocksdbTuwunel}/include";
            ROCKSDB_LIB_DIR = "${rocksdbTuwunel}/lib";
          };
          passthru = (old.passthru or { }) // {
            rocksdb = rocksdbTuwunel;
          };
        });
    })
  ];
}
