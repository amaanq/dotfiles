{ lib, pkgs, ... }:
let
  inherit (lib) theme;
  tomlFormat = pkgs.formats.toml { };

  settings = {
    limit = 0;

    keys = {
      # Navigation
      up = [
        "up"
        "k"
      ];
      down = [
        "down"
        "j"
      ];
      scroll_up = [
        "pgup"
        "K"
      ];
      scroll_down = [
        "pgdown"
        "J"
      ];
      jump_to_parent = [ "P" ];
      jump_to_children = [ "[" ];
      jump_to_working_copy = [ "@" ];

      # Actions
      apply = [ "enter" ];
      force_apply = [ "alt+enter" ];
      cancel = [ "esc" ];
      toggle_select = [ " " ];
      new = [ "n" ];
      commit = [ "c" ];
      refresh = [
        "R"
        "ctrl+r"
      ];
      abandon = [ "D" ];
      diff = [ "d" ];
      quit = [ "q" ];
      help = [ "?" ];
      edit = [ "e" ];
      force_edit = [ "alt+e" ];
      diffedit = [ "E" ];
      absorb = [ "A" ];
      split = [ "s" ];
      split_parallel = [ "alt+s" ];
      revset = [ "L" ];
      exec_jj = [ ":" ];
      exec_shell = [ "$" ];
      ace_jump = [ "f" ];
      quick_search = [ "/" ];
      quick_search_cycle = [ "'" ];
      custom_commands = [ "X" ];
      leader = [ "\\" ];
      suspend = [ "ctrl+z" ];
      set_parents = [ "M" ];

      rebase = {
        mode = [ "r" ];
        revision = [ "r" ];
        source = [ "s" ];
        branch = [ "B" ];
        target = [ "t" ];
        after = [ "a" ];
        before = [ "b" ];
        onto = [ "o" ];
        insert = [ "i" ];
        skip_emptied = [ "e" ];
      };

      revert = {
        mode = [ "t" ];
        target = [ "t" ];
        after = [ "a" ];
        before = [ "b" ];
        onto = [ "o" ];
        insert = [ "i" ];
      };

      duplicate = {
        mode = [ "y" ]; # y for yank/copy
        target = [ "t" ];
        after = [ "a" ];
        before = [ "b" ];
        onto = [ "o" ];
      };

      squash = {
        mode = [ "S" ];
        target = [ "t" ];
        keep_emptied = [ "e" ];
        use_destination_message = [ "d" ];
        interactive = [ "i" ];
      };

      details = {
        mode = [ "l" ];
        close = [
          "h"
          "esc"
        ];
        split = [ "s" ];
        split_parallel = [ "alt+s" ];
        squash = [ "S" ];
        restore = [ "r" ];
        absorb = [ "A" ];
        diff = [ "d" ];
        select = [
          "m"
          " "
        ];
        revisions_changing_file = [ "*" ];
      };

      evolog = {
        mode = [ "v" ];
        diff = [ "d" ];
        restore = [ "r" ];
      };

      preview = {
        mode = [ "p" ];
        toggle_bottom = [ "P" ];
        scroll_up = [ "ctrl+p" ];
        scroll_down = [ "ctrl+n" ];
        half_page_down = [ "ctrl+d" ];
        half_page_up = [ "ctrl+u" ];
        expand = [ ">" ];
        shrink = [ "<" ];
      };

      bookmark = {
        mode = [ "b" ];
        set = [
          "B"
          "n"
        ];
        delete = [ "d" ];
        move = [ "m" ];
        forget = [ "f" ];
        track = [ "t" ];
        untrack = [ "u" ];
      };

      inline_describe = {
        mode = [ "enter" ];
        accept = [
          "alt+enter"
          "ctrl+s"
        ];
        editor = [ "alt+e" ];
      };

      git = {
        mode = [ "g" ];
        push = [
          "P"
          "p"
        ];
        fetch = [ "f" ];
      };

      oplog = {
        mode = [ "o" ];
        restore = [ "r" ];
        revert = [ "R" ];
      };

      file_search = {
        toggle = [ "ctrl+t" ];
        up = [
          "up"
          "k"
        ];
        down = [
          "down"
          "j"
        ];
        accept = [ "enter" ];
        edit = [ "alt+e" ];
      };
    };

    ui = {
      theme = "";
      auto_refresh_interval = 0;
      flash_message_display_seconds = 4;
      tracer = {
        enabled = false;
      };
      colors = {
        # Rose Pine theme (matches Stylix)
        selected = {
          bg = "#${theme.base03}";
        };
      };
    };

    suggest = {
      exec = {
        mode = "fuzzy";
      };
    };

    revisions = {
      log_batching = true;
      log_batch_size = 50;
    };

    preview = {
      revision_command = [
        "show"
        "--color"
        "always"
        "-r"
        "$change_id"
      ];
      evolog_command = [
        "show"
        "--color"
        "always"
        "-r"
        "$commit_id"
      ];
      oplog_command = [
        "op"
        "show"
        "$operation_id"
        "--color"
        "always"
      ];
      file_command = [
        "diff"
        "--color"
        "always"
        "-r"
        "$change_id"
        "$file"
      ];
      position = "auto";
      show_at_start = true;
      width_percentage = 50.0;
      width_increment_percentage = 5.0;
    };

    oplog = {
      limit = 200;
    };

    git = {
      default_remote = "origin";
    };

    ssh = {
      hijack_askpass = false;
    };
  };
in
{
  environment.systemPackages = [ pkgs.jjui ];

  environment.shellAliases.jju = "jjui";

  environment.etc."jjui/config.toml".source = tomlFormat.generate "jjui-config" settings;

  environment.variables.JJUI_CONFIG_DIR = "/etc/jjui";
}
