{ lib, pkgs, ... }:
let
  inherit (lib) enabled;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      btop = prev.btop.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./cwd-detail.patch
        ];
      });
    })
  ];

  home-manager.sharedModules = [
    {
      programs.btop = enabled {
        settings = {
          # Appearance
          truecolor = true;
          rounded_corners = true;

          # Navigation
          vim_keys = true;

          # Layout and presets
          presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
          shown_boxes = "cpu mem net proc";

          # Graph settings
          graph_symbol = "braille";
          graph_symbol_cpu = "default";
          graph_symbol_mem = "default";
          graph_symbol_net = "default";
          graph_symbol_proc = "default";

          # Performance
          update_ms = 2000;

          # Process list
          proc_sorting = "user";
          proc_reversed = false;
          proc_tree = false;
          proc_colors = true;
          proc_gradient = true;
          proc_per_core = false;
          proc_mem_bytes = true;
          proc_cpu_graphs = true;
          proc_info_smaps = false;
          proc_left = false;
          proc_filter_kernel = false;

          # CPU settings
          cpu_graph_upper = "total";
          cpu_graph_lower = "total";
          cpu_invert_lower = true;
          cpu_single_graph = false;
          cpu_bottom = false;
          show_uptime = true;
          check_temp = true;
          cpu_sensor = "Auto";
          show_coretemp = true;
          cpu_core_map = "";
          temp_scale = "celsius";
          show_cpu_freq = true;
          custom_cpu_name = "";

          # General UI
          clock_format = "%X";
          background_update = true;
          base_10_sizes = false;

          # Memory and disk settings
          mem_graphs = true;
          mem_below_net = false;
          zfs_arc_cached = true;
          show_swap = true;
          swap_disk = true;
          show_disks = true;
          only_physical = true;
          use_fstab = true;
          zfs_hide_datasets = false;
          disk_free_priv = false;
          show_io_stat = true;
          io_mode = false;
          io_graph_combined = false;
          io_graph_speeds = "";
          disks_filter = "";

          # Network settings
          net_download = 100;
          net_upload = 100;
          net_auto = true;
          net_sync = true;
          net_iface = "";

          # Battery
          show_battery = true;
          selected_battery = "Auto";

          # Logging
          log_level = "WARNING";
        };
      };
    }
  ];
}
