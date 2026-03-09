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
    services.watt = enabled;

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

    # Use the most aggressive PCIe ASPM policy for idle power savings.
    boot.kernelParams = [ "pcie_aspm.policy=powersupersave" ];

    services.udev.extraRules = ''
      # Enable PCI runtime power management on all devices.
      ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"

      # Limit battery charge to 80% to preserve long-term health.
      # Charging resumes at 75% to avoid constant cycling.
      ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}="80"
      ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}="80"
      ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_start_threshold}="75"
      ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_start_threshold}="75"
    '';
  };
}
