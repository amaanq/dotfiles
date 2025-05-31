{
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  home-manager.sharedModules = [
    {
      programs.htop = enabled {
        settings = {
          # Version and compatibility
          htop_version = "3.3.0";
          config_reader_min_version = 3;

          # Column configuration
          fields = "0 48 17 18 38 39 40 2 46 47 49 1";

          # Thread and process visibility
          hide_kernel_threads = true;
          hide_userland_threads = true;
          hide_running_in_container = false;
          shadow_other_users = false;
          show_thread_names = false;
          show_program_path = true;

          # Highlighting options
          highlight_base_name = true;
          highlight_deleted_exe = true;
          shadow_distribution_path_prefix = false;
          highlight_megabytes = true;
          highlight_threads = true;
          highlight_changes = false;
          highlight_changes_delay_secs = 5;

          # Command line display
          find_comm_in_cmdline = true;
          strip_exe_from_cmdline = true;
          show_merged_command = false;

          # UI layout
          header_margin = true;
          screen_tabs = true;
          detailed_cpu_time = false;
          cpu_count_from_one = true;
          show_cpu_usage = true;
          show_cpu_frequency = false;
          show_cpu_temperature = false;
          degree_fahrenheit = false;
          update_process_names = false;
          account_guest_in_cpu_meter = false;

          # Appearance
          color_scheme = 0;
          enable_mouse = true;
          delay = 15;
          hide_function_bar = false;

          # Header layout configuration
          header_layout = "two_50_50";
          column_meters_0 = "LeftCPUs4 Memory Swap";
          column_meter_modes_0 = "1 1 1";
          column_meters_1 = "RightCPUs4 Tasks LoadAverage Uptime";
          column_meter_modes_1 = "1 2 2 2";

          # Sorting and view options
          tree_view = false;
          sort_key = 47;
          tree_sort_key = 0;
          sort_direction = -1;
          tree_sort_direction = 1;
          tree_view_always_by_pid = false;
          all_branches_collapsed = false;
        };
      };
    }
  ];
}
