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
    mkDefault
    mkIf
    optional
    optionals
    ;
  inherit (config)
    isDesktop
    isServer
    ;

  isAmd = config.cpuArch != null && hasPrefix "MZEN" config.cpuArch;
in
{
  disabledModules = [ "config/malloc.nix" ];

  bunker.kernel = enabled {
    inherit (config) cpuArch;
    interactive = mkIf isServer false;
    drivers = mkIf isServer false;
  };

  environment = {
    systemPackages = optional isDesktop pkgs.perf;
  };

  boot.kernel.sysctl = {
    # TCP performance for long-lived streams (SSE, websockets).
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Fixed byte caps so syncfs() doesn't stall on high-RAM machines.
    "vm.dirty_bytes" = mkDefault (2 * 1024 * 1024 * 1024); # 2 GiB
    "vm.dirty_background_bytes" = mkDefault (512 * 1024 * 1024); # 512 MiB
  };

  boot.extraModulePackages = optionals isAmd [ config.boot.kernelPackages.zenpower ];
  boot.blacklistedKernelModules = optionals isAmd [ "k10temp" ];

  boot.kernelParams = [
    "rootflags=noatime"
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"
  ]
  ++ optionals isDesktop [
    "mitigations=off"
  ];

  # Use GrapheneOS' hardened_malloc as the system allocator, and mimalloc as a fallback.
  environment.memoryAllocator = {
    provider = mkIf isDesktop "graphene-hardened";
    fallbackProvider = mkIf isDesktop "mimalloc";

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
