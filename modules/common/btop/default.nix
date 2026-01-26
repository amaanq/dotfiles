{ lib, pkgs, ... }:
let
  colors = lib.theme.withHashtag;

  btopPatched = pkgs.btop.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./cwd-detail.patch
    ];
  });
in
{
  wrappers.btop = {
    basePackage = btopPatched;
    systemWide = true;
    executables.btop.args.suffix = [
      "--config"
      "/etc/btop/btop.conf"
      "--themes-dir"
      "/etc/btop/themes"
    ];
  };

  environment.etc."btop/themes/rose-pine.theme".text = ''
    theme[main_bg]="${colors.base00}"
    theme[main_fg]="${colors.base05}"
    theme[title]="${colors.base05}"
    theme[hi_fg]="${colors.base0D}"
    theme[selected_bg]="${colors.base03}"
    theme[selected_fg]="${colors.base0D}"
    theme[inactive_fg]="${colors.base04}"
    theme[graph_text]="${colors.base06}"
    theme[meter_bg]="${colors.base03}"
    theme[proc_misc]="${colors.base06}"
    theme[cpu_box]="${colors.base0E}"
    theme[mem_box]="${colors.base0B}"
    theme[net_box]="${colors.base0C}"
    theme[proc_box]="${colors.base0D}"
    theme[div_line]="${colors.base01}"
    theme[temp_start]="${colors.base0B}"
    theme[temp_mid]="${colors.base0A}"
    theme[temp_end]="${colors.base08}"
    theme[cpu_start]="${colors.base0B}"
    theme[cpu_mid]="${colors.base0A}"
    theme[cpu_end]="${colors.base08}"
    theme[free_start]="${colors.base0A}"
    theme[free_mid]="${colors.base0B}"
    theme[free_end]="${colors.base0B}"
    theme[cached_start]="${colors.base0C}"
    theme[cached_mid]="${colors.base0C}"
    theme[cached_end]="${colors.base0A}"
    theme[available_start]="${colors.base08}"
    theme[available_mid]="${colors.base0A}"
    theme[available_end]="${colors.base0B}"
    theme[used_start]="${colors.base0A}"
    theme[used_mid]="${colors.base09}"
    theme[used_end]="${colors.base08}"
    theme[download_start]="${colors.base0B}"
    theme[download_mid]="${colors.base0A}"
    theme[download_end]="${colors.base08}"
    theme[upload_start]="${colors.base0B}"
    theme[upload_mid]="${colors.base0A}"
    theme[upload_end]="${colors.base08}"
    theme[process_start]="${colors.base0B}"
    theme[process_mid]="${colors.base0A}"
    theme[process_end]="${colors.base08}"
  '';

  environment.etc."btop/btop.conf".text = ''
    color_theme = "rose-pine"
    theme_background = False
    truecolor = True
    rounded_corners = True
    vim_keys = True
    presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty"
    shown_boxes = "cpu mem net proc"
    graph_symbol = "braille"
    graph_symbol_cpu = "default"
    graph_symbol_mem = "default"
    graph_symbol_net = "default"
    graph_symbol_proc = "default"
    update_ms = 2000
    proc_sorting = "user"
    proc_reversed = False
    proc_tree = False
    proc_colors = True
    proc_gradient = True
    proc_per_core = False
    proc_mem_bytes = True
    proc_cpu_graphs = True
    proc_info_smaps = False
    proc_left = False
    proc_filter_kernel = False
    cpu_graph_upper = "total"
    cpu_graph_lower = "total"
    cpu_invert_lower = True
    cpu_single_graph = False
    cpu_bottom = False
    show_uptime = True
    check_temp = True
    cpu_sensor = "Auto"
    show_coretemp = True
    cpu_core_map = ""
    temp_scale = "celsius"
    show_cpu_freq = True
    custom_cpu_name = ""
    clock_format = "%X"
    background_update = True
    base_10_sizes = False
    mem_graphs = True
    mem_below_net = False
    zfs_arc_cached = True
    show_swap = True
    swap_disk = True
    show_disks = True
    only_physical = True
    use_fstab = True
    zfs_hide_datasets = False
    disk_free_priv = False
    show_io_stat = True
    io_mode = False
    io_graph_combined = False
    io_graph_speeds = ""
    disks_filter = ""
    net_download = 100
    net_upload = 100
    net_auto = True
    net_sync = True
    net_iface = ""
    show_battery = True
    selected_battery = "Auto"
    log_level = "WARNING"
  '';
}
