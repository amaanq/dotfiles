{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;
in
{
  disabledModules = [ "config/malloc.nix" ];

  bunker.kernel = {
    enable = true;
    version = "6.19";
    cpuArch = mkIf config.isDesktop config.cpuArch;
    interactive = mkIf config.isServer false;
    drivers = mkIf config.isServer false;
    extras = mkIf config.isServer false;
  };

  environment = {
    systemPackages = [ pkgs.perf ];
  };

  boot.kernel.sysctl = {
    # TCP performance for long-lived streams (SSE, websockets).
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Fixed byte caps so syncfs() doesn't stall on high-RAM machines.
    "vm.dirty_bytes" = lib.mkDefault (2 * 1024 * 1024 * 1024);
    "vm.dirty_background_bytes" = lib.mkDefault (512 * 1024 * 1024);
  };

  boot.kernelParams = [
    "rootflags=noatime"
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"
  ]
  ++ optionals config.isDesktop [
    "mitigations=off"
  ];

  # Use GrapheneOS' hardened_malloc as the system allocator.
  environment.memoryAllocator = {
    provider = mkIf config.isDesktop "graphene-hardened";

    mozillaPackages = [
      pkgs.thunderbird
    ];

    excludedPackages = [
      config.nix.package
      config.programs.spicetify.spicedSpotify
    ];
  };
}
