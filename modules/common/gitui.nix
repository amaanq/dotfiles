{
  lib,
  ...
}:
let
  inherit (lib) enabled;
in
{
  home-manager.sharedModules = [
    (
      { config, ... }:
      {
        programs.gitui = enabled {
          theme = # ron
            ''
              (
                selected_tab: Some(Reset),
                command_fg: Some(White),
                selection_bg: Some(Blue),
                selection_fg: Some(White),
                cmdbar_bg: Some(Blue),
                cmdbar_extra_lines_bg: Some(Blue),
                disabled_fg: Some(DarkGray),
                diff_line_add: Some(Green),
                diff_line_delete: Some(Red),
                diff_file_added: Some(LightGreen),
                diff_file_removed: Some(LightRed),
                diff_file_moved: Some(LightMagenta),
                diff_file_modified: Some(Yellow),
                commit_hash: Some(Magenta),
                commit_time: Some(LightCyan),
                commit_author: Some(Green),
                danger_fg: Some(Red),
                push_gauge_bg: Some(Blue),
                push_gauge_fg: Some(Reset),
                tag_fg: Some(LightMagenta),
                branch_fg: Some(LightYellow),
              )
            '';

          keyConfig = # ron
            ''
              (
                open_help: Some(( code: F(1), modifiers: ( bits: 0,),)),

                move_left: Some(( code: Char('h'), modifiers: ( bits: 0,),)),
                move_right: Some(( code: Char('l'), modifiers: ( bits: 0,),)),
                move_up: Some(( code: Char('k'), modifiers: ( bits: 0,),)),
                move_down: Some(( code: Char('j'), modifiers: ( bits: 0,),)),

                popup_up: Some(( code: Char('p'), modifiers: ( bits: 0,),)),
                popup_down: Some(( code: Char('n'), modifiers: ( bits: 0,),)),
                page_up: Some(( code: Char('b'), modifiers: ( bits: 2,),)),
                page_down: Some(( code: Char('f'), modifiers: ( bits: 2,),)),
                home: Some(( code: Char('g'), modifiers: ( bits: 0,),)),
                end: Some(( code: Char('G'), modifiers: ( bits: 1,),)),

                shift_up: Some(( code: Char('K'), modifiers: ( bits: 1,),)),
                shift_down: Some(( code: Char('J'), modifiers: ( bits: 1,),)),

                edit_file: Some(( code: Char('I'), modifiers: ( bits: 1,),)),

                status_reset_item: Some(( code: Char('U'), modifiers: ( bits: 1,),)),

                diff_reset_lines: Some(( code: Char('u'), modifiers: ( bits: 0,),)),
                diff_stage_lines: Some(( code: Char('s'), modifiers: ( bits: 0,),)),

                stashing_save: Some(( code: Char('w'), modifiers: ( bits: 0,),)),
                stashing_toggle_index: Some(( code: Char('m'), modifiers: ( bits: 0,),)),

                stash_open: Some(( code: Char('l'), modifiers: ( bits: 0,),)),

                abort_merge: Some(( code: Char('M'), modifiers: ( bits: 1,),)),
              )
            '';
        };
      }
    )
  ];
}
