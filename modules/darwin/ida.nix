{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    head
    merge
    mkAfter
    mkIf
    ;

  user = head (attrNames config.users.users);

  ida-patcher = pkgs.writers.writePython3Bin "ida-patcher" {
    flakeIgnore = [
      "E501" # line too long (more than 79 characters)
    ];
  } (builtins.readFile (self + /modules/common/ida/patcher.py));

  idaZip = builtins.fetchurl {
    url = "https://cloud.amaanq.com/public.php/webdav/ida-pro_93_armmac.app.zip";
    sha256 = "dbbecf71f93ddc3e6a9b39f9779663e7dc2ee0eb732340a4320ae9bb79163735";
    name = "ida-pro_93_armmac.app.zip";
  };

  idaLauncher = pkgs.writeScript "ida-launcher" ''
    #!/bin/bash
    export QT_PLUGIN_PATH=/Applications/IDA/PlugIns
    exec /Applications/IDA/standalone/ida "$@"
  '';

  idaPlist = pkgs.writeText "ida-info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleExecutable</key>
        <string>IDA Pro</string>
        <key>CFBundleIdentifier</key>
        <string>com.hex-rays.ida64</string>
        <key>CFBundleName</key>
        <string>IDA Pro</string>
        <key>CFBundleDisplayName</key>
        <string>IDA Pro</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleIconFile</key>
        <string>appico</string>
        <key>CFBundleVersion</key>
        <string>9.3</string>
        <key>CFBundleShortVersionString</key>
        <string>9.3</string>
        <key>LSMinimumSystemVersion</key>
        <string>10.15</string>
        <key>NSHighResolutionCapable</key>
        <true/>
        <key>CFBundleDocumentTypes</key>
        <array>
            <dict>
                <key>CFBundleTypeName</key>
                <string>IDA Database</string>
                <key>CFBundleTypeExtensions</key>
                <array>
                    <string>idb</string>
                    <string>i64</string>
                </array>
                <key>CFBundleTypeRole</key>
                <string>Editor</string>
            </dict>
        </array>
    </dict>
    </plist>
  '';

  idaWrapper = pkgs.writeShellScriptBin "ida" ''
    export QT_PLUGIN_PATH=/Applications/IDA/PlugIns
    exec /Applications/IDA/standalone/ida "$@"
  '';

  ida64Wrapper = pkgs.writeShellScriptBin "ida64" ''
    export QT_PLUGIN_PATH=/Applications/IDA/PlugIns
    exec /Applications/IDA/standalone/ida "$@"
  '';

  idatWrapper = pkgs.writeShellScriptBin "idat" ''
    exec /Applications/IDA/standalone/idat "$@"
  '';
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    idaWrapper
    ida64Wrapper
    idatWrapper
  ];

  system.activationScripts.postActivation.text = mkAfter ''
    IDA_DIR="/Applications/IDA"
    IDA_APP="$IDA_DIR/IDA Professional 9.3.app"
    IDA_STANDALONE="$IDA_DIR/standalone"
    IDA_MARKER="$IDA_STANDALONE/.patched-9.3"

    if [ ! -f "$IDA_MARKER" ]; then
      echo "Installing and patching IDA Pro..."

      rm -rf "$IDA_DIR"

      TEMP_DIR=$(mktemp -d)
      ${pkgs.unzip}/bin/unzip -q -o ${idaZip} -d "$TEMP_DIR"

      "$TEMP_DIR/ida-pro_93_armmac.app/Contents/MacOS/osx-arm64" \
        --mode unattended \
        --prefix "$IDA_DIR"

      rm -rf "$TEMP_DIR"

      mkdir -p "$IDA_STANDALONE"
      /usr/bin/ditto "$IDA_APP/Contents/MacOS" "$IDA_STANDALONE"

      mkdir -p "$IDA_DIR/Frameworks" "$IDA_DIR/PlugIns"
      /usr/bin/ditto "$IDA_APP/Contents/Frameworks" "$IDA_DIR/Frameworks"
      /usr/bin/ditto "$IDA_APP/Contents/PlugIns" "$IDA_DIR/PlugIns"

      cd "$IDA_STANDALONE"
      ${ida-patcher}/bin/ida-patcher --oneshot

      if [ -f "$IDA_STANDALONE/cfg/hexrays.cfg" ]; then
        sed -i "" 's/MAX_FUNCSIZE            = 64/MAX_FUNCSIZE            = 1024/' "$IDA_STANDALONE/cfg/hexrays.cfg"
      fi

      # Configure Python 3.13 for IDAPython
      IDAUSR="/Users/${user}/.local/share/idapro" "$IDA_STANDALONE/idapyswitch" --force-path ${pkgs.python313}/lib/libpython3.13.dylib

      xattr -cr "$IDA_DIR"

      for lib in "$IDA_STANDALONE"/*.dylib; do
        codesign -fs - "$lib" 2>/dev/null || true
      done
      for exe in ida idat idapyswitch lsadm picture_decoder upg32; do
        if [ -f "$IDA_STANDALONE/$exe" ]; then
          codesign -fs - "$IDA_STANDALONE/$exe" 2>/dev/null || true
        fi
      done

      find "$IDA_DIR/Frameworks" -name "*.framework" -exec codesign -fs - --deep {} \; 2>/dev/null || true
      find "$IDA_DIR/PlugIns" -name "*.dylib" -exec codesign -fs - {} \; 2>/dev/null || true

      ICON_FILE="$IDA_APP/Contents/Resources/appico.icns"

      APP_BUNDLE="$IDA_DIR/IDA Pro.app"
      rm -rf "$APP_BUNDLE"
      mkdir -p "$APP_BUNDLE/Contents/MacOS"
      mkdir -p "$APP_BUNDLE/Contents/Resources"

      if [ -f "$ICON_FILE" ]; then
        cp "$ICON_FILE" "$APP_BUNDLE/Contents/Resources/appico.icns"
      fi

      rm -rf "$IDA_APP"

      cp ${idaLauncher} "$APP_BUNDLE/Contents/MacOS/IDA Pro"
      chmod +x "$APP_BUNDLE/Contents/MacOS/IDA Pro"
      cp ${idaPlist} "$APP_BUNDLE/Contents/Info.plist"

      codesign -fs - "$APP_BUNDLE" 2>/dev/null || true

      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"

      touch "$IDA_MARKER"

      echo "IDA Pro installed and patched successfully!"
    else
      echo "IDA Pro already installed and patched."
    fi

    mkdir -p "/Users/${user}/.idapro"
    mkdir -p "/Users/${user}/.local/share/idapro"
    chown ${user}:staff "/Users/${user}/.idapro" "/Users/${user}/.local/share/idapro"
  '';
}
