{
  config,
  lib,
  ...
}:
let
  inherit (lib) concatMapStringsSep mkAfter mkIf;

  cfg = config.chromiumExtensions;
  extensions = import ../../lib/chromium-extensions.nix;
  defaultUpdateUrl = cfg.updateUrl;
  bundleId = cfg.darwinBundleId;

  # If enabledExtensions is empty, use all extensions
  enabledKeys =
    if cfg.enabledExtensions == [ ] then builtins.attrNames extensions else cfg.enabledExtensions;

  # Build extension strings: "id;updateUrl"
  extensionForcelist = map (
    key:
    let
      ext = extensions.${key};
      url = ext.updateUrl or defaultUpdateUrl;
    in
    "${ext.id};${url}"
  ) enabledKeys;

  # Just the IDs for allowlist
  extensionIds = map (key: extensions.${key}.id) enabledKeys;

  # Generate plist content
  plistContent = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>ExtensionInstallForcelist</key>
      <array>
    ${concatMapStringsSep "\n" (e: "    <string>${e}</string>") extensionForcelist}
      </array>
      <key>ExtensionManifestV2Availability</key>
      <integer>2</integer>

      <!-- Privacy and security settings -->
      <key>PromotionsEnabled</key>
      <false/>
      <key>SyncDisabled</key>
      <true/>
      <key>DefaultBrowserSettingEnabled</key>
      <false/>
      <key>BackgroundModeEnabled</key>
      <false/>
      <key>MediaRecommendationsEnabled</key>
      <false/>
      <key>ShoppingListEnabled</key>
      <false/>
      <key>PrivacySandboxFingerprintingProtectionEnabled</key>
      <true/>
      <key>PrivacySandboxIpProtectionEnabled</key>
      <true/>
      <key>BlockThirdPartyCookies</key>
      <true/>
      <key>DnsOverHttpsMode</key>
      <string>automatic</string>
      <key>MetricsReportingEnabled</key>
      <false/>
      <key>SafeBrowsingExtendedReportingEnabled</key>
      <false/>
      <key>UrlKeyedAnonymizedDataCollectionEnabled</key>
      <false/>
      <key>FeedbackSurveysEnabled</key>
      <false/>
      <key>PasswordManagerEnabled</key>
      <false/>
      <key>PasswordSharingEnabled</key>
      <false/>
      <key>PasswordLeakDetectionEnabled</key>
      <false/>
      <key>AutofillAddressEnabled</key>
      <false/>
      <key>AutofillCreditCardEnabled</key>
      <false/>
      <key>DefaultGeolocationSetting</key>
      <integer>2</integer>
      <key>DefaultNotificationsSetting</key>
      <integer>2</integer>
      <key>DefaultLocalFontsSetting</key>
      <integer>2</integer>
      <key>DefaultSensorsSetting</key>
      <integer>2</integer>
      <key>DefaultSerialGuardSetting</key>
      <integer>2</integer>
      <key>RelatedWebsiteSetsEnabled</key>
      <false/>
      <key>BrowserSignin</key>
      <integer>0</integer>
      <key>QuicAllowed</key>
      <true/>
      <key>AlwaysOpenPdfExternally</key>
      <false/>
      <key>SpellcheckEnabled</key>
      <false/>
      <key>BrowserGuestModeEnabled</key>
      <false/>
      <key>AlternateErrorPagesEnabled</key>
      <false/>
      <key>ExtensionInstallAllowlist</key>
      <array>
    ${concatMapStringsSep "\n" (id: "    <string>${id}</string>") extensionIds}
      </array>
      <key>ExtensionInstallSources</key>
      <array>
        <string>https://services.helium.imput.net/*</string>
        <string>https://rednoise.org/*</string>
        <string>https://gitflic.ru/*</string>
      </array>
    </dict>
    </plist>
  '';
in
{
  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = mkAfter ''
      # Install Chromium extension policy
      echo "Installing Chrome/Chromium extension policy for ${bundleId}..."
      mkdir -p "/Library/Managed Preferences"
      cat > "/Library/Managed Preferences/${bundleId}.plist" << 'PLIST_EOF'
      ${plistContent}
      PLIST_EOF
      chmod 644 "/Library/Managed Preferences/${bundleId}.plist"
      chown root:wheel "/Library/Managed Preferences/${bundleId}.plist"

      # Also install for Google Chrome if using a different browser as primary
      if [ "${bundleId}" != "com.google.Chrome" ]; then
        cat > "/Library/Managed Preferences/com.google.Chrome.plist" << 'PLIST_EOF'
      ${plistContent}
      PLIST_EOF
        chmod 644 "/Library/Managed Preferences/com.google.Chrome.plist"
        chown root:wheel "/Library/Managed Preferences/com.google.Chrome.plist"
      fi
    '';
  };
}
