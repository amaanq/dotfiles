{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    merge
    mkIf
    ;

  avbroot = pkgs.avbroot.overrideAttrs (oldAttrs: rec {
    version = "3.23.2";
    src = pkgs.fetchFromGitHub {
      owner = "chenxiaolong";
      repo = "avbroot";
      rev = "v${version}";
      hash = "sha256-rS3V+D7dBt/px0UNC8ZZyQ4FzNsjTykMSeXbjFF6iis=";
    };
    cargoHash = "sha256-v1oR5z7g7jjJgPiE56wYA3s4bF41QV6JRs7iMumfKnI=";
  });
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "android-sdk-ndk"
    "android-sdk-platform-tools"
    "platform-tools"
    "ndk"
  ];

  environment.systemPackages = [
    pkgs.android-tools
    pkgs.androidenv.androidPkgs.ndk-bundle
    pkgs.androidenv.androidPkgs.platform-tools
    pkgs.git-repo
    pkgs.scrcpy
    avbroot
  ];
}
