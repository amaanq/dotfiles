{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) merge mkIf;

  ida-patcher = pkgs.writers.writePython3Bin "ida-patcher" {
    flakeIgnore = [
      "E501" # line too long (more than 79 characters)
    ];
  } (builtins.readFile ./patch.py);

  baseIdaPro = pkgs.callPackage pkgs.ida-pro {
    runfile = builtins.fetchurl {
      url = "file://${toString ./.}/modules/linux/ida-pro_91_x64linux.run";
      sha256 = "1qpr02bkq6yhd3fpzgnbzmnb4mhk1l0h3sp3m69zc3ispqi81w4g";
    };
  };

  patchedIdaPro = baseIdaPro.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ ida-patcher ];
    postInstall = (old.postInstall or "") + ''
      cd $out/opt
      ${ida-patcher}/bin/ida-patcher $out
      # Copy license to where IDA expects it
      cp *.hexlic $out/opt/ || true
    '';
  });
in
merge
<| mkIf (config.isDesktop && !config.isVirtual) {
  unfree.allowedNames = [
    "ida-pro"
  ];

  environment.systemPackages = [
    patchedIdaPro
  ];
}
