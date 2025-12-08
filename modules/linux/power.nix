{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled mkIf;
in
{
  config = mkIf config.isLaptop {
    services.watt.enable = true;

    services.upower = enabled {
      percentageLow = 15;
      percentageCritical = 5;
    };

    services.acpid = enabled {
      logEvents = true;
    };

    environment.systemPackages = [ pkgs.acpi ];

    boot.kernelModules = [ "acpi_call" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
  };
}
