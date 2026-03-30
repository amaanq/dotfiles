{
  pkgs,
  ...
}:
{
  unfree.allowedNames = [
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
    pkgs.android-tools
    pkgs.avbroot
    pkgs.git-repo
    pkgs.gnirehtet
    (pkgs.jadx.override { quark-engine = pkgs.emptyDirectory; })
    pkgs.scrcpy
  ];

  environment.variables = {
    ANDROID_USER_HOME = "$HOME/.local/share/android";
    GRADLE_USER_HOME = "$XDG_DATA_HOME/gradle";
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java";
  };
}
