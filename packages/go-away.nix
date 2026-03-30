{
  lib,
  buildGoModule,
  go_1_25,
  fetchFromGitea,

  # asset compression
  brotli,
  zopfli,

  # wasm compilation
  clang,
  tinygo,
}:

buildGoModule.override { go = go_1_25; } {
  pname = "go-away";
  version = "0-unstable-2025-09-04";

  src = fetchFromGitea {
    domain = "git.gammaspectra.live";
    owner = "git";
    repo = "go-away";
    rev = "95ac08540b8cf45a5e4e6fce0758ed52113bc893";
    hash = "sha256-UgqpHDWbB/wADWCTlh6lyzqGZpQ3NX3IcIsgzB8X80c=";
  };

  vendorHash = "sha256-OWkqvrOp59WDc5DxRrbGXksJSjPCHA/+g5P42hTBpdQ=";
  proxyVendor = true;

  nativeBuildInputs = [
    brotli
    zopfli
    clang
    tinygo
  ];

  postPatch = ''
    patchShebangs *.sh
  '';

  preBuild = ''
    ./build-compress.sh
    export HOME=$(mktemp -d)
    go generate -v ./...
  '';

  subPackages = [ "cmd/go-away" ];

  postInstall = ''
    mkdir -p $out/lib/go-away
    cp -rv examples/snippets $out/lib/go-away/
  '';

  meta = {
    description = "Self-hosted abuse detection and rule enforcement against low-effort mass AI scraping and bots";
    homepage = "https://git.gammaspectra.live/git/go-away";
    license = lib.licenses.mit;
    mainProgram = "go-away";
  };
}
