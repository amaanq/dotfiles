{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;
  inherit (lib.kernel)
    freeform
    option
    yes
    no
    ;

  # Full LLVM stdenv with clang + lld + llvm-ar/nm (required for LTO_CLANG)
  llvmStdenv = pkgs.overrideCC pkgs.llvmPackages.stdenv (
    pkgs.llvmPackages.clang.override {
      bintools = pkgs.llvmPackages.bintools;
    }
  );

  vanillaLinuxSrc = pkgs.fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.19.tar.xz";
    hash = "sha256-MDB5qCULjzgfgrA/kEY9EqyY1PaxSbdh6nWvEyNSE1c=";
  };

  bunkerPatchesSrc = pkgs.fetchFromGitHub {
    owner = "amaanq";
    repo = "bunker-patches";
    rev = "main";
    hash = "sha256-B6116TASNV/9S1GpxO9KKUWCNXdvQLGnmf8/8wgRTg8=";
  };

  bunkerPatches =
    let
      patchDir = "${bunkerPatchesSrc}/patches/6.19";
      patchNames = builtins.filter (n: lib.hasSuffix ".patch" n) (
        builtins.attrNames (builtins.readDir patchDir)
      );
    in
    map (name: {
      inherit name;
      patch = "${patchDir}/${name}";
    }) (builtins.sort builtins.lessThan patchNames);

  bunkernel = pkgs.linuxKernel.buildLinux {
    pname = "linux-bunker";
    stdenv = llvmStdenv;
    src = vanillaLinuxSrc;
    version = "6.19.0";
    modDirVersion = "6.19.0-bunker";
    kernelPatches = bunkerPatches;

    structuredExtraConfig = {
      BUNKERNEL = yes;
      LOCALVERSION = freeform "-bunker";
      SCHED_POC_SELECTOR = yes;

      # Preempt (low-latency desktop)
      PREEMPT = lib.mkOverride 90 yes;
      PREEMPT_VOLUNTARY = lib.mkOverride 90 no;

      # 1000Hz tick
      HZ = freeform "1000";
      HZ_1000 = yes;

      # FQ-Codel packet scheduling
      NET_SCH_DEFAULT = yes;
      DEFAULT_FQ_CODEL = yes;

      # BFQ I/O scheduler
      IOSCHED_BFQ = lib.mkOverride 90 yes;

      # BBRv3 as default TCP congestion control
      TCP_CONG_BBR = yes;
      DEFAULT_BBR = yes;

      # Futex / NTSYNC for Wine/Proton
      FUTEX = yes;
      FUTEX_PI = yes;
      NTSYNC = yes;

      # Preemptible tree-based hierarchical RCU
      TREE_RCU = yes;
      PREEMPT_RCU = yes;
      RCU_EXPERT = yes;
      TREE_SRCU = yes;
      TASKS_RCU_GENERIC = yes;
      TASKS_RCU = yes;
      TASKS_RUDE_RCU = yes;
      TASKS_TRACE_RCU = yes;
      RCU_STALL_COMMON = yes;
      RCU_NEED_SEGCBLIST = yes;
      RCU_FANOUT = freeform "64";
      RCU_FANOUT_LEAF = freeform "16";
      RCU_BOOST = yes;
      RCU_BOOST_DELAY = option (freeform "500");
      RCU_NOCB_CPU = yes;
      RCU_LAZY = yes;
      RCU_DOUBLE_CHECK_CB_TIME = yes;

      # Disable BTF to allow RUST + LTO + CFI
      # (BTF + LTO + RUST is blocked upstream due to pahole limitations)
      DEBUG_INFO_BTF = lib.mkForce no;
      # These may not exist depending on toolchain/BTF state — use option to suppress errors
      NOVA_CORE = lib.mkForce (option no);
      NET_SCH_BPF = lib.mkForce (option no);
      SCHED_CLASS_EXT = lib.mkForce (option no);
      MODULE_ALLOW_BTF_MISMATCH = lib.mkForce (option no);

      # Full LTO with Clang
      LTO_CLANG_FULL = yes;
      LTO_CLANG_THIN = lib.mkForce no;

      # Per-host micro-architecture target (reproducible, unlike -march=native)
      ${config.cpuArch} = yes;

      # Always use THP (zen defaults to madvise)
      TRANSPARENT_HUGEPAGE_ALWAYS = lib.mkForce yes;
      TRANSPARENT_HUGEPAGE_MADVISE = lib.mkForce no;

      # AMD P-State EPP in active mode (mode 3)
      X86_AMD_PSTATE = yes;
      X86_AMD_PSTATE_DEFAULT_MODE = freeform "3";

      # ZSTD for kernel modules
      MODULE_COMPRESS_ZSTD = lib.mkForce yes;
      MODULE_COMPRESS_XZ = lib.mkForce no;

      # Control Flow Integrity (CFI) with Clang
      CFI = yes;
      CFI_PERMISSIVE = no;

      # Wipe CPU registers on return (prevents ROP attacks)
      ZERO_CALL_USED_REGS = yes;

      # Restrict setuid operations
      SECURITY_SAFESETID = yes;

      # Controls the behavior of vsyscalls. This has been defaulted to none back in 2016 - break really old binaries for security.
      LEGACY_VSYSCALL_NONE = yes;

      # Make stack-based attacks on the kernel harder.
      RANDOMIZE_KSTACK_OFFSET_DEFAULT = yes;

      # Reduce most of the exposure of a heap attack to a single cache.
      SLAB_MERGE_DEFAULT = no;

      # Disable Kyber IO scheduler — NVMe drives have hardware scheduling
      MQ_IOSCHED_KYBER = lib.mkForce no;

      # Disable writeback throttling, it's designed for slow SATA but only adds overhead on NVMe
      BLK_WBT = lib.mkForce no;
      BLK_WBT_MQ = lib.mkForce (option no);
    };

    extraMeta = {
      branch = "6.19";
      description = "Bunkernel - custom kernel with zen/xanmod/cachyos patches";
    };
  };

  kernelPackage =
    if config.isServer then
      pkgs.linuxPackages_latest
    else
      pkgs.linuxKernel.packagesFor (
        bunkernel.overrideAttrs (old: {
          # Fix rust/Makefile being stripped during kernel build
          # This is needed for rust-analyzer support in out-of-tree Rust kernel modules
          postInstall =
            builtins.replaceStrings
              [ "# Keep whole scripts dir" ]
              [
                ''
                  # Keep rust Makefile and source files for rust-analyzer support
                            [ -f rust/Makefile ] && chmod u-w rust/Makefile
                            find rust -type f -name '*.rs' -print0 | xargs -0 -r chmod u-w

                            # Keep whole scripts dir''
              ]
              (old.postInstall or "");

        })
      );
in
{
  disabledModules = [ "config/malloc.nix" ];

  # Fix nuke-refs corrupting zstd-compressed kernel modules.
  # nuke-refs replaces Nix store path hashes inside .ko.zst files. If the
  # hash survives compression as literal bytes, the zstd stream is corrupted
  # and the decompressed ELF gets truncated (ENOEXEC). The fix: decompress
  # before nuke-refs, then recompress.
  nixpkgs.overlays = [
    (final: prev: {
      # bcachefs-tools DKMS module supports 6.19 upstream but nixpkgs
      # hasn't bumped the version cap yet.
      bcachefs-tools = prev.bcachefs-tools.overrideAttrs (old: {
        passthru = old.passthru // {
          kernelModule =
            let
              origFn = old.passthru.kernelModule;
              newFn =
                args:
                (origFn args).overrideAttrs (kold: {
                  meta = kold.meta // {
                    broken = false;
                  };
                });
            in
            lib.setFunctionArgs newFn (builtins.functionArgs origFn);
        };
      });

      makeModulesClosure =
        args:
        (prev.makeModulesClosure args).overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [
            final.zstd
            final.xz
          ];
          builder = final.writeScript "modules-closure.sh" (
            builtins.replaceStrings
              [ ''nuke-refs "$target"'' ]
              [
                ''
                  case "$target" in
                    *.zst)
                      ${final.zstd}/bin/zstd -d -q "$target"
                      nuke-refs "''${target%.zst}"
                      ${final.zstd}/bin/zstd -q --rm "''${target%.zst}" -o "$target"
                      ;;
                    *.xz)
                      ${final.xz}/bin/xz -d "$target"
                      nuke-refs "''${target%.xz}"
                      ${final.xz}/bin/xz "''${target%.xz}"
                      ;;
                    *)
                      nuke-refs "$target"
                      ;;
                  esac''
              ]
              (builtins.readFile old.builder)
          );
        });
    })
  ];

  boot.kernelPackages = kernelPackage;

  environment = {
    sessionVariables = {
      KDIR = "${kernelPackage.kernel.dev}/lib/modules/${kernelPackage.kernel.modDirVersion}/build";
    };
    systemPackages = [ pkgs.perf ];
  };

  # Credits:
  # - https://github.com/NotAShelf/nyx/blob/main/modules/core/common/system/security/kernel.nix
  # - "hsslister" user - raf (NotAShelf) - "I actually forgot the dudes GitHub"
  boot.kernel.sysctl = {
    # The Magic SysRq key is a key combo that allows users connected to the
    # system console of a Linux kernel to perform some low-level commands.
    # Disable it, since we don't need it, and is a potential security concern.
    "kernel.sysrq" = 0;

    # Hide kptrs even for processes with CAP_SYSLOG.
    # Also prevents printing kernel pointers.
    "kernel.kptr_restrict" = 2;

    # Disable bpf() JIT (to eliminate spray attacks).
    "net.core.bpf_jit_enable" = false;

    # Disable ftrace debugging.
    "kernel.ftrace_enabled" = false;

    # Avoid kernel memory address exposures via dmesg (this value can also be set by CONFIG_SECURITY_DMESG_RESTRICT).
    "kernel.dmesg_restrict" = 1;

    # Prevent unintentional fifo writes.
    "fs.protected_fifos" = 2;

    # Prevent unintended writes to already-created files.
    "fs.protected_regular" = 2;

    # Disable SUID binary dump.
    "fs.suid_dumpable" = 0;

    # Disallow profiling at all levels without CAP_SYS_ADMIN.
    "kernel.perf_event_paranoid" = 3;

    # Require CAP_BPF to use bpf.
    "kernel.unprivileged_bpf_disabled" = 1;

    # Disable kexec which can be used to replace the running kernel.
    "kernel.kexec_load_disabled" = 1;

    # Network hardening.
    # SYN flood protection - uses SYN cookies when SYN queue fills up.
    "net.ipv4.tcp_syncookies" = 1;

    # TIME-WAIT assassination protection (RFC 1337).
    "net.ipv4.tcp_rfc1337" = 1;

    # Reverse path filtering - drop packets with spoofed source addresses.
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # Disable ICMP redirects - prevents MITM via fake route injection.
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;

    # Disable source routing - ancient feature, only useful for attackers.
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;

    # Log packets with impossible addresses.
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # TCP performance for long-lived streams (SSE, websockets).
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Buffer more dirty pages before flushing, which reduces write stalls during
    # parallel builds
    "vm.dirty_ratio" = 40;
    "vm.dirty_background_ratio" = 20;
  };

  # https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
  boot.kernelParams = [
    # Only allow signed modules.
    "module.sig_enforce=1"

    # Blocks access to all kernel memory, even preventing administrators from being able to inspect and probe the kernel.
    "lockdown=confidentiality"

    # Performance improvement for direct-mapped memory-side-cache utilization, reduces the predictability of page allocations.
    "page_alloc.shuffle=1"

    # Disable sysrq keys. sysrq is seful for debugging, but also insecure.
    "sysrq_always_enabled=0"

    # Ignore access time (atime) updates on files, except when they coincide with updates to the ctime or mtime.
    "rootflags=noatime"

    # Linux security modules.
    "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"

    # Prevent the kernel from blanking plymouth out of the fb.
    "fbcon=nodefer"

    # Don't expose kernel memory.
    "kcore=off"
  ]
  ++ optionals config.isDesktop [
    # Disable CPU vulnerability mitigations (Spectre, Meltdown, etc.) for performance on desktops
    "mitigations=off"
  ];

  boot.blacklistedKernelModules = [
    # Obscure network protocols.
    "af_802154" # IEEE 802.15.4
    "appletalk" # Appletalk
    "atm" # ATM
    "ax25" # Amatuer X.25
    "can" # Controller Area Network
    "dccp" # Datagram Congestion Control Protocol
    "decnet" # DECnet
    "econet" # Econet
    "ipx" # Internetwork Packet Exchange
    "n-hdlc" # High-level Data Link Control
    "netrom" # NetRom
    "p8022" # IEEE 802.3
    "p8023" # Novell raw IEEE 802.3
    "psnap" # SubnetworkAccess Protocol
    "rds" # Reliable Datagram Sockets
    "rose" # ROSE
    "sctp" # Stream Control Transmission Protocol
    "tipc" # Transparent Inter-Process Communication
    "x25" # X.25

    # Old or rare or insufficiently audited filesystems.
    "adfs" # Active Directory Federation Services
    "affs" # Amiga Fast File System
    "befs" # "Be File System"
    "bfs" # BFS, used by SCO UnixWare OS for the /stand slice
    "cifs" # Common Internet File System
    "cramfs" # compressed ROM/RAM file system
    "efs" # Extent File System
    "erofs" # Enhanced Read-Only File System
    "exofs" # EXtended Object File System
    "f2fs" # Flash-Friendly File System
    "freevxfs" # Veritas filesystem driver
    "gfs2" # Global File System 2
    "hfs" # Hierarchical File System (Macintosh)
    "hfsplus" # Same as above, but with extended attributes.
    "hpfs" # High Performance File System (used by OS/2)
    "jffs2" # Journalling Flash File System (v2)
    "jfs" # Journaled File System - only useful for VMWare sessions
    "ksmbd" # SMB3 Kernel Server
    "minix" # minix fs - used by the minix OS
    "nfs" # Network File System
    "nfsv3" # Network File System (v3)
    "nfsv4" # Network File System (v4)
    "nilfs2" # New Implementation of a Log-structured File System
    "omfs" # Optimized MPEG Filesystem
    "qnx4" # Extent-based file system used by the QNX4 OS.
    "qnx6" # Extent-based file system used by the QNX6 OS.
    "squashfs" # compressed read-only file system (used by live CDs)
    "sysv" # implements all of Xenix FS, SystemV/386 FS and Coherent FS.
    "udf" # https://docs.kernel.org/5.15/filesystems/udf.html
    "vivid" # Virtual Video Test Driver (unnecessary)

    # Disable Thunderbolt and FireWire to prevent DMA attacks.
    "firewire-core"
    "firewire_core"
    "firewire-ohci"
    "firewire_ohci"
    "firewire-sbp2"
    "firewire_sbp2"
    "ohci1394"
    "sbp2"
    "dv1394"
    "raw1394"
    "video1394"
    "thunderbolt"
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

    excludedCommands = [
      "ckati"
    ];
  };
}
