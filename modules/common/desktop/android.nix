{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionals;

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
    "android-studio"
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
    (pkgs.jadx.override {
      quark-engine = pkgs.quark-engine.override {
        python3Packages = pkgs.python3Packages.overrideScope (
          _: prev: { plotly = prev.plotly.overridePythonAttrs { doCheck = false; }; }
        );
      };
    })
    pkgs.scrcpy
  ]
  ++ optionals config.isLinux [
    pkgs.android-studio
  ];

  environment.variables = {
    ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
    ANDROID_USER_HOME = "$HOME/.local/share/android";
    GRADLE_USER_HOME = "$XDG_DATA_HOME/gradle";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java";
  };
}
