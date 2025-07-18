{
  system.defaults.NSGlobalDomain = {
    NSDocumentSaveNewDocumentsToCloud = false;
  };

  system.defaults.LaunchServices = {
    LSQuarantine = false;
  };

  system.defaults.CustomSystemPreferences."com.apple.AdLib" = {
    allowApplePersonalizedAdvertising = false;
    allowIdentifierForAdvertising = false;
    forceLimitAdTracking = true;
    personalizedAdsMigrated = false;
  };

  system.startup.chime = false;

  # Stop login print in shell
  home-manager.sharedModules = [
    {
      home.file.".hushlogin".text = "";
    }
  ];
}
