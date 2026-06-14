{ pkgs, ... }:
let
  xcode = pkgs.requireFile {
    name = "Xcode.app";
    hashMode = "recursive";
    hash = "sha256-UBDey19uBljjRw84bY4rzxetFEkHiXLEj39Q578jYL8=";
    message = ''
      Extract the Xcode xip on the mac, then:
        nix store add --name Xcode.app ./Xcode.app
    '';
  };
in
{
  unfree.allowedNames = [
    "Xcode.app"
  ];

  environment.systemPackages = [ xcode ];

  system.activationScripts.postActivation.text = ''
    /usr/bin/sudo /usr/bin/xcode-select -s ${xcode}/Contents/Developer 2>/dev/null || true
    /usr/bin/sudo /usr/bin/xcodebuild -license accept 2>/dev/null || true
  '';
}
