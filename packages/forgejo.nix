# Forgejo 14.0.0 - copied from nixpkgs master
{
  lib,
  bash,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitea,
  git,
  gzip,
  makeWrapper,
  openssh,
  sqliteSupport ? true,
}:

let
  version = "14.0.0";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "forgejo";
    repo = "forgejo";
    rev = "refs/tags/v${version}";
    hash = "sha256-kQaaRwVUYIYTTjWcHKb09CzygDR6lhEbnY3FOsnyYpg=";
  };

  frontend = buildNpmPackage {
    pname = "forgejo-frontend";
    inherit src version;
    npmDepsHash = "sha256-rdlVXdoov3zppDgoLODl22AKCdm+AXiV1O63dmo6trg=";
    buildPhase = "./node_modules/.bin/webpack";
    installPhase = ''
      mkdir $out
      cp -R ./public $out/
    '';
  };
in
buildGoModule {
  pname = "forgejo";
  inherit version src;

  vendorHash = "sha256-7xgm57IqsFOh3CPwGybPHLLlckGLplJpU7M5upYKBl8=";

  subPackages = [
    "."
    "contrib/environment-to-ini"
  ];

  outputs = [
    "out"
    "data"
  ];

  nativeBuildInputs = [ makeWrapper ];

  tags = lib.optionals sqliteSupport [
    "sqlite"
    "sqlite_unlock_notify"
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
    "-X 'main.Tags=${
      lib.concatStringsSep " " (
        lib.optionals sqliteSupport [
          "sqlite"
          "sqlite_unlock_notify"
        ]
      )
    }'"
  ];

  preConfigure = ''
    export ldflags+=" -X main.ForgejoVersion=$(GITEA_VERSION=${version} make show-version-api)"
  '';

  doCheck = false;

  preInstall = ''
    mv "$GOPATH/bin/forgejo.org" "$GOPATH/bin/forgejo"
  '';

  postInstall = ''
    mkdir $data
    cp -R ./{templates,options} ${frontend}/public $data
    mkdir -p $out
    cp -R ./options/locale $out/locale
    wrapProgram $out/bin/forgejo \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          git
          gzip
          openssh
        ]
      }
  '';

  meta = {
    description = "Self-hosted lightweight software forge";
    homepage = "https://forgejo.org";
    license = lib.licenses.gpl3Plus;
    mainProgram = "forgejo";
  };
}
