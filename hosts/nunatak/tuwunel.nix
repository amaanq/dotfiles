_: {
  nixpkgs.overlays = [
    (final: prev: {
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
                    # Sob
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
