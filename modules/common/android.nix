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
    optionals
    ;
in
merge
<| mkIf config.isDesktop (
  let
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
      androidComposition.androidsdk
      pkgs.android-tools
      pkgs.avbroot
      pkgs.git-repo
      pkgs.gnirehtet
      pkgs.jadx
      pkgs.scrcpy
    ]
    ++ optionals config.isLinux [
      pkgs.android-studio
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
