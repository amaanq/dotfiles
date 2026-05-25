{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) enabled;

  bcachefsShrink = pkgs.writeShellScript "bcachefs-btree-cache-shrink" /* sh */ ''
    set -eu

    to_bytes() {
      ${pkgs.gawk}/bin/awk '
        function mult(s) {
          if (s == "K") return 1024
          if (s == "M") return 1024 * 1024
          if (s == "G") return 1024 * 1024 * 1024
          if (s == "T") return 1024 * 1024 * 1024 * 1024
          return 1
        }
        {
          v = $1
          s = substr(v, length(v), 1)
          if (s ~ /[kKmMgGtT]/) {
            s = toupper(s)
            sub(/[kKmMgGtT]$/, "", v)
            printf "%.0f\n", v * mult(s)
          } else {
            printf "%.0f\n", v
          }
        }'
    }

    soft=$((16 * 1024 * 1024 * 1024))
    hard=$((32 * 1024 * 1024 * 1024))

    for d in /sys/fs/bcachefs/*; do
      [ -r "$d/btree_cache_size" ] || continue
      [ -w "$d/internal/trigger_btree_cache_shrink" ] || continue
      echo 0 > "$d/options/btree_node_prefetch" 2>/dev/null || true

      bytes=$(to_bytes < "$d/btree_cache_size")
      passes=0
      if [ "$bytes" -ge "$hard" ]; then
        passes=8
      elif [ "$bytes" -ge "$soft" ]; then
        passes=3
      fi

      i=0
      while [ "$i" -lt "$passes" ]; do
        echo 200000 > "$d/internal/trigger_btree_cache_shrink" || true
        i=$((i + 1))
      done
    done
  '';
in
{
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [
    "ddcci_backlight"
    "i2c-dev"
    "kvm-amd"
  ];
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = enabled {
    pkiBundle = "/var/lib/sbctl";
  };
  boot.plymouth = enabled {
    # drop the X11 ply-gtk-renderer. NixOS's plymouth module unconditionally
    # `rm`s renderers/x11.so to slim the initrd, so leave a stub behind to keep
    # that step happy.
    package = pkgs.plymouth.overrideAttrs (old: {
      buildInputs = lib.filter (p: p.pname or "" != "gtk+3") old.buildInputs;
      mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dgtk=disabled" ];
      postInstall = (old.postInstall or "") + /* sh */ ''
        touch $out/lib/plymouth/renderers/x11.so
      '';
    });
  };
  boot.supportedFilesystems = [ "bcachefs" ];

  # RDNA 4 (RX 9070 XT / Navi 48) workaround stack for the open upstream regression:
  # https://gitlab.freedesktop.org/drm/amd/-/issues/5185 (6.19 drops off PCIe bus; 6.18 clean)
  # Plus 40+ sibling tickets with amdgpu_dm_atomic_commit_tail → flip_done timeout.
  #
  # Symptom we hit: kworker D-state in drm_atomic_helper_wait_for_flip_done, cascades into
  # un-SIGKILL-able Chromium renderers stuck in close()→shmem_undo_range.
  # No upstream fix commit exists yet — AMD asking for bisects.
  #
  # 0x21C10 = PSR (0x10) + Panel Replay (0x400) + IPS (0x800) + IPS_DYNAMIC (0x1000)
  #         + SUBVP_FAMS (0x20000)
  # SUBVP_FAMS (Firmware-Assisted Memclk Switching) is the load-bearing bit per gitlab #5113.
  # runpm=0 prevents "device lost from bus" at idle. reset_method=4 = mode1+bus_reset
  # (best recovery path for this class, though prevention > recovery).
  boot.kernelParams = [
    "boot.shell_on_fail"
    "efi=disable_early_pci_dma" # opt-in only; kills iGPU DMA on laptops. safe with dGPU
    "amdgpu.mcbp=0" # Disable mid-command buffer preemption (primary MES fix)
    "amdgpu.sg_display=0" # Disable scatter-gather display (reduces TLB pressure)
    "amdgpu.dcdebugmask=0x21C10" # PSR+Replay+IPS+IPS_DYN+SubVP/FAMS — Navi 48 flip_done stack
    "amdgpu.runpm=0" # Disable runtime PM — Navi 48 drops off PCIe bus at idle otherwise
    "amdgpu.reset_method=4" # mode1+bus_reset — best chance to recover from hung DC
    "amdgpu.gpu_recovery=1" # Auto-recover from hangs if they still occur
    # MES(1) failed to respond to msg=INVALIDATE_TLBS hard-locked the box on 6.19.9
    # (2026-04-26 ~01:34). Known gfx12 race: pipe0+pipe1 share invalidation engine 5
    # in MES fw <0x83. CWSR uses MES heavily and is the most common trigger on
    # RDNA3/RDNA4 in 6.18/6.19 — see ROCm#5590, ROCm#5724, Framework critical-bugs thread.
    "amdgpu.cwsr_enable=0"
  ];

  fileSystems."/" = {
    device = "UUID=fef71188-998b-4a00-a263-6b525fe9832b";
    fsType = "bcachefs";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/boot";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.i2c = enabled;
  hardware.keyboard.qmk = enabled;
  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  # Workaround for RX 9070 power management crash (https://gitlab.freedesktop.org/drm/amd/-/issues/4829)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="high"
  '';

  # Realtek RTL8125 NIC workarounds (disable offloading and EEE to fix driver issues cuz realtek sucks)
  systemd.services.ethtool-enp18s0 = {
    description = "Configure ethtool settings for enp18s0";
    after = [ "sys-subsystem-net-devices-enp18s0.device" ];
    wantedBy = [ "sys-subsystem-net-devices-enp18s0.device" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ethtool-enp18s0" /* sh */ ''
        ${pkgs.ethtool}/bin/ethtool -K enp18s0 gso off gro off tso off
        ${pkgs.ethtool}/bin/ethtool --set-eee enp18s0 eee off
        ${pkgs.ethtool}/bin/ethtool -A enp18s0 autoneg off rx off tx off
      '';
    };
  };

  systemd.services."bcachefs-memory-tune" = {
    description = "Apply low-memory bcachefs runtime tuning";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "bcachefs-memory-tune" /* sh */ ''
        for d in /sys/fs/bcachefs/*; do
          echo 0 > "$d/options/btree_node_prefetch" 2>/dev/null || true
        done
      '';
    };
  };

  systemd.services."bcachefs-btree-cache-shrink" = {
    description = "Shrink bcachefs btree cache above high-water marks";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = bcachefsShrink;
    };
  };

  systemd.timers."bcachefs-btree-cache-shrink" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "90s";
      AccuracySec = "15s";
      Unit = "bcachefs-btree-cache-shrink.service";
    };
  };

  # 8GB dirty page cap for Android builds.
  boot.kernel.sysctl."vm.dirty_bytes" = 8 * 1024 * 1024 * 1024;
  boot.kernel.sysctl."vm.dirty_background_bytes" = 2 * 1024 * 1024 * 1024;

  environment.systemPackages = [
    pkgs.sbctl
  ];
}
