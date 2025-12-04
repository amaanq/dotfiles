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
in
merge
<| mkIf config.isDesktop (
  let
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

    androidComposition = pkgs.androidenv.composeAndroidPackages {
      buildToolsVersions = [ "35.0.0" ];
      includeNDK = true;
      includeSources = false;
      includeSystemImages = false;
      includeEmulator = false;
      extraLicenses = [
        "android-sdk-license"
      ];
    };
  in
  {
    nixpkgs.config.android_sdk.accept_license = true;

    unfree.allowedNames = [
      "android-studio-stable"
      "android-sdk-ndk"
      "android-sdk-build-tools"
      "android-sdk-cmdline-tools"
      "android-sdk-platform-tools"
      "android-sdk-platforms"
      "android-sdk-tools"
      "build-tools"
      "cmake"
      "cmdline-tools"
      "ndk"
      "platform-tools"
      "platforms"
      "tools"
    ];

    environment.systemPackages = [
      pkgs.android-studio
      pkgs.android-tools
      androidComposition.androidsdk
      pkgs.git-repo
      pkgs.jadx
      pkgs.scrcpy
      avbroot
    ];

    home-manager.sharedModules = [
      (
        { config, ... }:
        {
          home.sessionVariables = {
            ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
            ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
          };
        }
      )
    ];
  }
)
