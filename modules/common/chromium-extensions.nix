{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.chromiumExtensions = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable chromium extension policies";
    };

    enabledExtensions = mkOption {
      type = types.listOf types.str;
      default = [ ]; # Empty = all extensions from lib/chromium-extensions.nix
      description = "List of extension keys to enable via policy. Empty list means all.";
    };

    updateUrl = mkOption {
      type = types.str;
      default = "https://services.helium.imput.net/ext";
      description = "Chrome extension update URL (Helium proxy)";
    };

    darwinBundleId = mkOption {
      type = types.str;
      default = "org.chromium.Chromium";
      description = "macOS bundle identifier for the browser";
    };
  };
}
