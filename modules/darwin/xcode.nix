{ config, lib, pkgs, ... }:
{
  unfree.allowedNames = [
    "Xcode.app"
  ];

  # Xcode.app is already in the nix store at this path
  environment.systemPackages = [
    /nix/store/zkl1l5cfsv2k7x2s7szg2n8qnwhgyvfr-Xcode.app
  ];

  # Point xcode-select to our nix store Xcode and accept license
  system.activationScripts.postActivation.text = ''
    echo "Setting xcode-select to Nix store Xcode..."
    /usr/bin/sudo /usr/bin/xcode-select -s /nix/store/zkl1l5cfsv2k7x2s7szg2n8qnwhgyvfr-Xcode.app/Contents/Developer 2>/dev/null || true
    echo "Accepting Xcode license..."
    /usr/bin/sudo /usr/bin/xcodebuild -license accept 2>/dev/null || true
  '';
}
