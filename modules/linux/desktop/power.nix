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
    services.watt = enabled {
      settings.rule = [
        # Thermal emergency — always wins.
        {
          name = "emergency-thermal-protection";
          "if" = { is-more-than = 95.0; value = "$cpu-temperature"; };
          priority = 100;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "power"; "then" = "power"; };
          cpu.frequency-mhz-maximum = { "if" = "?frequency-available"; "then" = 2000; };
          cpu.governor = { "if".is-governor-available = "powersave"; "then" = "powersave"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = false; };
        }

        # Critical battery — aggressive savings.
        {
          name = "critical-battery-preservation";
          "if".all = [ "?discharging" { is-less-than = 0.3; value = "%power-supply-charge"; } ];
          priority = 90;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "power"; "then" = "power"; };
          cpu.governor = { "if".is-governor-available = "powersave"; "then" = "powersave"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = false; };
          power.platform-profile = { "if".is-platform-profile-available = "low-power"; "then" = "low-power"; };
        }

        # High CPU load — max performance regardless of power source.
        {
          name = "high-load-performance";
          "if".all = [
            { is-more-than = 0.8; value = "%cpu-usage"; }
            { is-less-than = 30.0; value = "$cpu-idle-seconds"; }
            { is-less-than = 75.0; value = "$cpu-temperature"; }
          ];
          priority = 80;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "performance"; "then" = "performance"; };
          cpu.governor = { "if".is-governor-available = "performance"; "then" = "performance"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = true; };
        }

        # AC plugged in — always max performance (no CPU usage gate).
        {
          name = "ac-always-performance";
          "if" = { "not" = "?discharging"; };
          priority = 75;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "performance"; "then" = "performance"; };
          cpu.governor = { "if".is-governor-available = "performance"; "then" = "performance"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = true; };
        }

        # Moderate load on battery — balanced.
        {
          name = "moderate-load-balanced";
          "if".all = [
            { is-more-than = 0.4; value = "%cpu-usage"; }
            { is-less-than = 0.8; value = "%cpu-usage"; }
          ];
          priority = 60;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "balance_performance"; "then" = "balance_performance"; };
          cpu.governor = { "if".is-governor-available = "schedutil"; "then" = "schedutil"; };
        }

        # Idle on battery — power saving.
        {
          name = "low-activity-power-saving";
          "if".all = [
            "?discharging"
            { is-less-than = 0.2; value = "%cpu-usage"; }
            { is-more-than = 60.0; value = "$cpu-idle-seconds"; }
          ];
          priority = 50;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "power"; "then" = "power"; };
          cpu.governor = { "if".is-governor-available = "powersave"; "then" = "powersave"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = false; };
        }

        # Extended idle on battery — deep power saving.
        {
          name = "extended-idle-power-saving";
          "if".all = [
            "?discharging"
            { is-more-than = 300.0; value = "$cpu-idle-seconds"; }
          ];
          priority = 40;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "power"; "then" = "power"; };
          cpu.frequency-mhz-maximum = { "if" = "?frequency-available"; "then" = 1600; };
          cpu.governor = { "if".is-governor-available = "powersave"; "then" = "powersave"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = false; };
        }

        # Discharging below 50% — conserve battery.
        {
          name = "discharging-battery-conservation";
          "if".all = [ "?discharging" { is-less-than = 0.5; value = "%power-supply-charge"; } ];
          priority = 30;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "power"; "then" = "power"; };
          cpu.frequency-mhz-maximum = { "if" = "?frequency-available"; "then" = 2000; };
          cpu.governor = { "if".is-governor-available = "powersave"; "then" = "powersave"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = false; };
          power.platform-profile = { "if".is-platform-profile-available = "low-power"; "then" = "low-power"; };
        }

        # Any discharge — balanced battery mode.
        {
          name = "battery-balanced";
          "if" = "?discharging";
          priority = 20;
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "power"; "then" = "power"; };
          cpu.frequency-mhz-maximum = { "if" = "?frequency-available"; "then" = 1800; };
          cpu.frequency-mhz-minimum = { "if" = "?frequency-available"; "then" = 200; };
          cpu.governor = { "if".is-governor-available = "powersave"; "then" = "powersave"; };
          cpu.turbo = { "if" = "?turbo-available"; "then" = false; };
        }

        # Fallback — balanced.
        {
          name = "default-balanced";
          cpu.energy-performance-preference = { "if".is-energy-performance-preference-available = "balance_performance"; "then" = "balance_performance"; };
          cpu.governor = { "if".is-governor-available = "schedutil"; "then" = "schedutil"; };
          priority = 0;
        }
      ];
    };

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
