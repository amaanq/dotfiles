{ lib, pkgs, ... }:
let
  colors = lib.theme.withHashtag;

  yaziTheme = pkgs.writeText "theme.toml" ''
    # Rose Pine theme for Yazi

    [mgr]
    cwd = { fg = "${colors.foam}" }
    hovered = { bg = "${colors.base02}", bold = true }
    preview_hovered = { bg = "${colors.base02}", bold = true }
    find_keyword = { fg = "${colors.pine}", bold = true }
    find_position = { fg = "${colors.iris}" }
    marker_selected = { fg = "${colors.gold}", bg = "${colors.gold}" }
    marker_copied = { fg = "${colors.pine}", bg = "${colors.pine}" }
    marker_cut = { fg = "${colors.love}", bg = "${colors.love}" }
    border_style = { fg = "${colors.base04}" }
    count_copied = { fg = "${colors.base00}", bg = "${colors.pine}" }
    count_cut = { fg = "${colors.base00}", bg = "${colors.love}" }
    count_selected = { fg = "${colors.base00}", bg = "${colors.gold}" }

    [tabs]
    active = { fg = "${colors.base00}", bg = "${colors.iris}", bold = true }
    inactive = { fg = "${colors.iris}", bg = "${colors.base01}" }

    [mode]
    normal_main = { fg = "${colors.base00}", bg = "${colors.iris}", bold = true }
    normal_alt = { fg = "${colors.iris}", bg = "${colors.base00}" }
    select_main = { fg = "${colors.base00}", bg = "${colors.pine}", bold = true }
    select_alt = { fg = "${colors.pine}", bg = "${colors.base00}" }
    unset_main = { fg = "${colors.base00}", bg = "${colors.gold}", bold = true }
    unset_alt = { fg = "${colors.gold}", bg = "${colors.base00}" }

    [status]
    progress_label = { fg = "${colors.base05}", bg = "${colors.base00}" }
    progress_normal = { fg = "${colors.base05}", bg = "${colors.base00}" }
    progress_error = { fg = "${colors.love}", bg = "${colors.base00}" }
    perm_type = { fg = "${colors.iris}" }
    perm_read = { fg = "${colors.gold}" }
    perm_write = { fg = "${colors.love}" }
    perm_exec = { fg = "${colors.pine}" }
    perm_sep = { fg = "${colors.foam}" }

    [pick]
    border = { fg = "${colors.iris}" }
    active = { fg = "${colors.iris}" }
    inactive = { fg = "${colors.base05}" }

    [input]
    border = { fg = "${colors.iris}" }
    title = { fg = "${colors.base05}" }
    value = { fg = "${colors.base05}" }
    selected = { bg = "${colors.base03}" }

    [completion]
    border = { fg = "${colors.iris}" }
    active = { fg = "${colors.iris}", bg = "${colors.base03}" }
    inactive = { fg = "${colors.base05}" }

    [tasks]
    border = { fg = "${colors.iris}" }
    title = { fg = "${colors.base05}" }
    hovered = { fg = "${colors.base05}", bg = "${colors.base03}" }

    [which]
    mask = { bg = "${colors.base02}" }
    cand = { fg = "${colors.foam}" }
    rest = { fg = "${colors.gold}" }
    desc = { fg = "${colors.base05}" }
    separator_style = { fg = "${colors.base04}" }

    [help]
    on = { fg = "${colors.iris}" }
    run = { fg = "${colors.foam}" }
    desc = { fg = "${colors.base05}" }
    hovered = { fg = "${colors.base05}", bg = "${colors.base03}" }
    footer = { fg = "${colors.base05}" }

    [filetype]
    rules = [
      { mime = "image/*", fg = "${colors.foam}" },
      { mime = "video/*", fg = "${colors.gold}" },
      { mime = "audio/*", fg = "${colors.gold}" },
      { mime = "application/zip", fg = "${colors.iris}" },
      { mime = "application/gzip", fg = "${colors.iris}" },
      { mime = "application/tar", fg = "${colors.iris}" },
      { mime = "application/bzip", fg = "${colors.iris}" },
      { mime = "application/bzip2", fg = "${colors.iris}" },
      { mime = "application/7z-compressed", fg = "${colors.iris}" },
      { mime = "application/rar", fg = "${colors.iris}" },
      { mime = "application/xz", fg = "${colors.iris}" },
      { mime = "application/doc", fg = "${colors.pine}" },
      { mime = "application/pdf", fg = "${colors.pine}" },
      { mime = "application/rtf", fg = "${colors.pine}" },
      { mime = "application/vnd.*", fg = "${colors.pine}" },
      { mime = "inode/directory", fg = "${colors.iris}", bold = true },
      { mime = "*", fg = "${colors.base05}" },
    ]
  '';

in
{
  environment.systemPackages = [ pkgs.yazi ];
  environment.etc."yazi/theme.toml".source = yaziTheme;
  environment.variables.YAZI_CONFIG_HOME = "/etc/yazi";
}
