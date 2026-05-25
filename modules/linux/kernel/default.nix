{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    enabled
    hasPrefix
    mkIf
    optionals
    ;
  isAmd = config.cpuArch != null && hasPrefix "MZEN" config.cpuArch;
in
{
  disabledModules = [ "config/malloc.nix" ];

  bunker.kernel = enabled {
    inherit (config) cpuArch;
    interactive = mkIf config.isServer false;
    drivers = mkIf config.isServer false;
    extras = mkIf config.isServer false;
  };

  environment = {
    systemPackages = lib.optional config.isDesktop pkgs.perf;
  };

  boot.kernel.sysctl = {
    # TCP performance for long-lived streams (SSE, websockets).
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Fixed byte caps so syncfs() doesn't stall on high-RAM machines.
    "vm.dirty_bytes" = lib.mkDefault (2 * 1024 * 1024 * 1024);
    "vm.dirty_background_bytes" = lib.mkDefault (512 * 1024 * 1024);
  };

  boot.extraModulePackages = optionals isAmd [ config.boot.kernelPackages.zenpower ];
  boot.blacklistedKernelModules = optionals isAmd [ "k10temp" ];

  boot.kernelParams = [
    "rootflags=noatime"
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"
  ]
  ++ optionals config.isDesktop [
    "mitigations=off"
  ];

  # Use GrapheneOS' hardened_malloc as the system allocator, and mimalloc as a fallback.
  environment.memoryAllocator = {
    provider = mkIf config.isDesktop "graphene-hardened";
    fallbackProvider = mkIf config.isDesktop "mimalloc";

    mozillaPackages = [
      pkgs.thunderbird
    ];

    excludedPackages = [
      config.nix.package
      config.programs.claude-code.package
      config.programs.codex.package
      config.programs.niri.package
      config.neovimPackage
      pkgs.kitty
    ];
  };
}
