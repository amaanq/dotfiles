{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    merge
    mkIf
    ;
in
merge
<| mkIf config.isDesktop {
  unfree.allowedNames = [
    "android-sdk-emulator"
    "android-sdk-system-image-32-google_apis-arm64-v8a-system-image-32-google_apis-x86_64"
    "android-sdk-system-image-32-google_apis_playstore-arm64-v8a-system-image-32-google_apis_playstore-x86_64"
    "android-sdk-system-image-33-google_apis-arm64-v8a-system-image-33-google_apis-x86_64"
    "android-sdk-system-image-33-google_apis_playstore-arm64-v8a-system-image-33-google_apis_playstore-x86_64"
    "android-sdk-system-image-34-google_apis-arm64-v8a-system-image-34-google_apis-x86_64"
    "android-sdk-system-image-34-google_apis_playstore-arm64-v8a-system-image-34-google_apis_playstore-x86_64"
    "android-sdk-system-image-35-google_apis-arm64-v8a-system-image-35-google_apis-x86_64"
    "android-sdk-system-image-35-google_apis_playstore-arm64-v8a-system-image-35-google_apis_playstore-x86_64"
    "android-sdk-system-image-36-google_apis-arm64-v8a-system-image-36-google_apis-x86_64"
    "android-sdk-system-image-36-google_apis_playstore-arm64-v8a-system-image-36-google_apis_playstore-x86_64"
    "android-sdk-ndk"
    "android-sdk-platform-tools"
    "android-sdk-tools"
  ];

  environment.systemPackages = attrValues {
    inherit (pkgs) android-tools;

    inherit (pkgs.androidenv.androidPkgs)
      emulator
      ndk-bundle
      platform-tools
      tools
      ;
  };
}
