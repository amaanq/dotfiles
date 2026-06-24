{ pkgs, ... }:
let
  hammerspoonBuildScript = pkgs.writeShellScript "build-hammerspoon" ''
    set -e
    cd /Users/amaanq/projects/hammerspoon

    rm -rf build

    /usr/bin/xcodebuild \
      -scheme Hammerspoon \
      -configuration Release \
      -derivedDataPath ./build \
      CODE_SIGN_IDENTITY="" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO

    echo "Build complete: /Users/amaanq/projects/hammerspoon/build/Build/Products/Release/Hammerspoon.app"
  '';

  hammerspoonCustom = pkgs.runCommand "hammerspoon-custom" { } ''
    mkdir -p "$out/Applications"
    if [ -d "/Users/amaanq/projects/hammerspoon/build/Build/Products/Release/Hammerspoon.app" ]; then
      ln -s "/Users/amaanq/projects/hammerspoon/build/Build/Products/Release/Hammerspoon.app" "$out/Applications/Hammerspoon.app"
    else
      echo "Please build Hammerspoon first by running:"
      echo "  cd /Users/amaanq/projects/hammerspoon && ${hammerspoonBuildScript}"
      mkdir -p "$out/Applications/Hammerspoon.app"
    fi
  '';
in
{
  environment.systemPackages = [ hammerspoonCustom ];

  # Point Hammerspoon directly to /etc/hammerspoon
  system.activationScripts.postActivation.text = ''
    /usr/bin/defaults write org.hammerspoon.Hammerspoon MJConfigFile /etc/hammerspoon/init.lua
  '';
}
