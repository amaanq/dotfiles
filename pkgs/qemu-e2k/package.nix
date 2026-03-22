{
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  zlib,
  pkg-config,
  glib,
  buildPackages,
  pixman,
  flex,
  bison,
  ninja,
  meson,
  perl,
  makeWrapper,
  removeReferencesTo,
  libslirp,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qemu-e2k";
  version = "9.2.50-unstable-2025-04-13";

  src = fetchFromGitHub {
    owner = "OpenE2K";
    repo = "qemu-e2k";
    rev = "ebc4bbdbe5d74bbf5a59784f697a6df64a9aa299";
    hash = "sha256-XT4JxXz6bdMZ+lN1n1cuXdp/wxrzPh4rmH16ZSwOtEI=";
    fetchSubmodules = true;
  };

  depsBuildBuild = [
    buildPackages.stdenv.cc
  ];

  nativeBuildInputs = [
    makeWrapper
    removeReferencesTo
    pkg-config
    flex
    bison
    meson
    ninja
    perl
    python3Packages.distlib
    python3Packages.python
  ];

  buildInputs = [
    glib
    zlib
    pixman
    libslirp
  ];

  dontUseMesonConfigure = true;
  dontAddStaticConfigureFlags = true;

  preConfigure = ''
    unset CPP
    chmod +x ./scripts/shaderinclude.py
    patchShebangs .
    mv VERSION QEMU_VERSION
    substituteInPlace configure \
      --replace-fail '$source_path/VERSION' '$source_path/QEMU_VERSION'
    substituteInPlace meson.build \
      --replace-fail "'VERSION'" "'QEMU_VERSION'"

    # Remove fp test subproject that requires git to download berkeley-softfloat-3
    echo "" > tests/fp/meson.build
  '';

  configureFlags = [
    "--target-list=e2k-linux-user,e2k32-linux-user"
    "--disable-system"
    "--disable-tools"
    "--disable-docs"
    "--disable-guest-agent"
    "--disable-strip"
    "--cross-prefix=${stdenv.cc.targetPrefix}"
  ];

  preBuild = "cd build";

  doCheck = false;

  postInstall = ''
    # Remove unnecessary files
    rm -rf $out/share/applications
  '';

  meta = {
    description = "QEMU with Elbrus 2000 (E2K) user-mode emulation support";
    homepage = "https://github.com/OpenE2K/qemu-e2k";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "qemu-e2k";
  };
})
