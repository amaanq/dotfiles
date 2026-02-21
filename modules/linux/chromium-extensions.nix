{
  config,
  lib,
  ...
}:
let
  inherit (lib) enabled mkIf theme;

  cfg = config.chromiumExtensions;
  isServer = config.type == "server";
  extensions = import ../../lib/chromium-extensions.nix;
  defaultUpdateUrl = cfg.updateUrl;

  # If enabledExtensions is empty, use all extensions
  enabledKeys =
    if cfg.enabledExtensions == [ ] then builtins.attrNames extensions else cfg.enabledExtensions;

  # Build extension strings: "id;updateUrl"
  extensionStrings = map (
    key:
    let
      ext = extensions.${key};
      url = ext.updateUrl or defaultUpdateUrl;
    in
    "${ext.id};${url}"
  ) enabledKeys;

  # Just the IDs for allowlist
  extensionIds = map (key: extensions.${key}.id) enabledKeys;
in
{
  config = mkIf (cfg.enable && !isServer) {
    programs.chromium = enabled {
      extensions = extensionStrings;

      extraOpts = {
        # Rose Pine theme color
        BrowserThemeColor = theme.withHashtag.base00;

        # Disable promotions and sync
        PromotionsEnabled = false;
        SyncDisabled = true;

        # Setting the policy to False stops Google Chrome from ever checking if
        # it's the default and turns user controls off for this option.
        DefaultBrowserSettingEnabled = false;

        # In background mode, a Google Chrome process is started on OS sign-in and keeps
        # running when the last browser window is closed, allowing background apps and
        # the browsing session to remain active.
        BackgroundModeEnabled = false;

        # By default the browser will show media recommendations that are personalized to the user.
        # Setting this policy to Disabled will result in these recommendations being hidden from the user.
        MediaRecommendationsEnabled = false;

        # This policy controls the availability of the shopping list feature.
        # If enabled, users will be presented with UI to track the price of
        # the product displayed on the current page. The tracked product will
        # be shown in the bookmarks side panel. If this policy is set to Enabled
        # or not set, the shopping list feature will be available to users.
        # If this policy is set to Disabled, the shopping list feature will be unavailable.
        ShoppingListEnabled = false;

        PrivacySandboxFingerprintingProtectionEnabled = true;
        PrivacySandboxIpProtectionEnabled = true;
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Kagi";
        DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
        DefaultSearchProviderNewTabURL = "https://kagi.com";
        SearchSuggestEnabled = true;
        DefaultSearchProviderSuggestURL = "https://kagi.com/api/autosuggest?q={searchTerms}";

        # Prevents webpage elements that aren't from the domain
        # that's in the browser's address bar from setting cookies.
        BlockThirdPartyCookies = true;
        DnsOverHttpsMode = "automatic";
        MetricsReportingEnabled = false;
        SafeBrowsingExtendedReportingEnabled = false;

        # Setting the policy to Enabled means URL-keyed anonymized data collection,
        # which sends URLs of pages the user visits to Google to make searches and
        # browsing better, is always active.
        # Setting the policy to Disabled results in no URL-keyed anonymized data collection.
        UrlKeyedAnonymizedDataCollectionEnabled = false;

        # Google Chrome in-product surveys collect user feedback for the browser.
        # Survey responses are not associated with user accounts. When this policy
        # is Enabled or not set, in-product surveys may be shown to users.
        # When this policy is Disabled, in-product surveys are not shown to users.
        FeedbackSurveysEnabled = false;

        PasswordManagerEnabled = false;
        # Disable sharing user credentials with other users
        PasswordSharingEnabled = false;
        # Disable leak detection for entered credentials
        PasswordLeakDetectionEnabled = false;

        # Disable autofill
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;

        # Setting the policy to 2 denies sites tracking the users' physical locationing.
        DefaultGeolocationSetting = 2;
        DefaultNotificationsSetting = 3;
        # Setting the policy to BlockLocalFonts (value 2) automatically denies the local fonts
        # permission to sites by default. This will limit the ability of sites to see
        # information about local fonts.
        DefaultLocalFontsSetting = 2;

        # Setting the policy to 1 lets websites access and use sensors such as motion and light.
        # Setting the policy to 2 denies access to sensors.
        DefaultSensorsSetting = 2;
        # Setting the policy to 3 lets websites ask for access to serial ports.
        # Setting the policy to 2 denies access to serial ports.
        DefaultSerialGuardSetting = 2;
        # This policy allows to control the Related Website Sets feature enablement.
        # This policy overrides the FirstPartySetsEnabled policy.
        # When this policy is set to False, the Related Website Sets feature is disabled.
        RelatedWebsiteSetsEnabled = false;

        # This policy controls the sign-in behavior of the browser.
        # It allows you to specify if the user can sign in to Google Chrome with
        # their account and use account related services like Google Chrome Sync.
        BrowserSignin = 0;

        QuicAllowed = true;

        # Setting the policy to Enabled turns the internal PDF viewer off in Google Chrome,
        # treats PDF files as a download, and lets users open PDFs with the default application.
        AlwaysOpenPdfExternally = false;

        SpellcheckEnabled = false;

        # If this policy is set to Disabled, Google Chrome will not allow guest profiles to be started.
        # Guest logins are Google Chrome profiles where all windows are in incognito mode.
        BrowserGuestModeEnabled = false;

        # Setting the policy to True means Google Chrome uses alternate error
        # pages built into (such as "page not found"). Setting the policy to
        # False means Google Chrome never uses alternate error pages.
        AlternateErrorPagesEnabled = false;

        # Explicitly allow our extensions
        ExtensionInstallAllowlist = extensionIds;

        # Allow extensions from Helium proxy and self-hosted sources
        ExtensionInstallSources = [
          "https://services.helium.imput.net/*" # Helium proxy
          "https://rednoise.org/*" # AdNauseam manifest
          "https://github.com/*" # AdNauseam CRX host
          "https://*.githubusercontent.com/*" # GitHub release assets
          "https://gitflic.ru/*" # Bypass Paywalls
        ];
      };
    };
  };
}
