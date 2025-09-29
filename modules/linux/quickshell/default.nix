{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled merge mkIf;
in
merge
<| mkIf config.isDesktop {
  environment.systemPackages = [
    pkgs.quickshell
  ];

  environment.sessionVariables = {
    QS_NO_RELOAD_POPUP = "1";
    QML_DISABLE_DISK_CACHE = "1";
    QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/${pkgs.qt6.qtbase.qtQmlPrefix}";
  };

  home-manager.sharedModules = [
    {
      imports = [
        inputs.dankMaterialShell.homeModules.dankMaterialShell.default
        inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
      ];

      programs.dankMaterialShell = enabled;
    }
  ];
}
