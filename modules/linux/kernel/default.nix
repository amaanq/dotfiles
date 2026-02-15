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

  bunker.kernel = mkIf pkgs.stdenv.hostPlatform.isx86_64 {
    enable = true;
    version = "6.19";
    cpuArch = mkIf config.isDesktop config.cpuArch;
    interactive = mkIf config.isServer false;
    drivers = mkIf config.isServer false;
    extras = mkIf config.isServer false;
  };

  boot.kernelPackages = mkIf pkgs.stdenv.hostPlatform.isAarch64 pkgs.linuxPackages_latest;

  environment = {
    systemPackages = [ pkgs.perf ];
  };

  boot.kernel.sysctl = {
    # TCP performance for long-lived streams (SSE, websockets).
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Buffer more dirty pages before flushing, which reduces write stalls during
    # parallel builds.
    "vm.dirty_ratio" = 40;
    "vm.dirty_background_ratio" = 20;
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
      config.programs.spicetify.spicedSpotify
      pkgs.android-studio
    ];
  };
}
