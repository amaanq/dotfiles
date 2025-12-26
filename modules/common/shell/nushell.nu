use std/clip
use std null_device

$env.config.history.file_format = "sqlite"
$env.config.history.isolation = false
$env.config.history.max_size = 10_000_000
$env.config.history.sync_on_enter = true

$env.config.show_banner = false

$env.config.rm.always_trash = false

$env.config.recursion_limit = 100

$env.config.edit_mode = "vi"

$env.config.cursor_shape.emacs = "line"       # Cursor shape in emacs mode
$env.config.cursor_shape.vi_insert = "line"   # Cursor shape in vi-insert mode
$env.config.cursor_shape.vi_normal = "block"  # Cursor shape in normal vi mode

$env.CARAPACE_BRIDGES = "inshellisense,carapace,zsh,fish,bash"

$env.config.completions.algorithm = "prefix"
$env.config.completions.sort = "smart"
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true
$env.config.completions.use_ls_colors = true

$env.config.use_kitty_protocol = true

$env.config.shell_integration.osc2 = true
$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc9_9 = false
$env.config.shell_integration.osc8 = true
$env.config.shell_integration.osc133 = true
$env.config.shell_integration.osc633 = true
$env.config.shell_integration.reset_application_mode = true

$env.config.bracketed_paste = true

$env.config.use_ansi_coloring = "auto"

$env.config.error_style = "fancy"

$env.config.highlight_resolved_externals = true

$env.config.display_errors.exit_code = false
$env.config.display_errors.termination_signal = true

$env.config.footer_mode = 25

$env.config.table.mode = "rounded"
$env.config.table.index_mode = "always"
$env.config.table.show_empty = true
$env.config.table.padding.left = 1
$env.config.table.padding.right = 1
$env.config.table.trim.methodology = "wrapping"
$env.config.table.trim.wrapping_try_keep_words = true
$env.config.table.trim.truncating_suffix =  "..."
$env.config.table.header_on_separator = false
$env.config.table.abbreviated_row_count = null
$env.config.table.footer_inheritance = true
$env.config.table.missing_value_symbol = $"(ansi magenta_bold)nope(ansi reset)"

$env.config.datetime_format.table = null
$env.config.datetime_format.normal = "%m/%d/%y %I:%M:%S%p"

$env.config.filesize.unit = "metric"
$env.config.filesize.show_unit = true
$env.config.filesize.precision = 1

$env.config.render_right_prompt_on_last_line = false

$env.config.float_precision = 2

$env.config.ls.use_ls_colors = true

$env.config.hooks.pre_prompt = []

$env.config.hooks.pre_execution = [
  {||
    commandline
    | str trim
    | if ($in | is-not-empty) { print $"(ansi title)($in) — nu(char bel)" }
  }
]

$env.config.hooks.env_change = {}

$env.config.hooks.display_output = {||
  tee { table --expand | print }
  # SQLiteDatabase doesn't support equality comparisions
  | try { if $in != null { $env.last = $in } }
}

$env.config.hooks.command_not_found = []

# `nu-highlight` with default colors
#
# Custom themes can produce a lot more ansi color codes and make the output
# exceed discord's character limits
def nu-highlight-default [] {
  let input = $in
  $env.config.color_config = {}
  $input | nu-highlight
}

# Copy the current commandline, add syntax highlighting, wrap it in a
# markdown code block, copy that to the system clipboard.
#
# Perfect for sharing code snippets on Discord.
def "nu-keybind commandline-copy" []: nothing -> nothing {
  commandline
  | nu-highlight-default
  | [
    "```ansi"
    $in
    "```"
  ]
  | str join (char nl)
  | clip copy --ansi
}

$env.config.keybindings ++= [
  {
    name: copy_color_commandline
    modifier: control_alt
    keycode: char_c
    mode: [ emacs vi_insert vi_normal ]
    event: {
      send: executehostcommand
      cmd: 'nu-keybind commandline-copy'
    }
  }
]

$env.config.keybindings ++= [
  {
    name: insert_last_token
    modifier: alt
    keycode: char_.
    mode: [emacs vi_normal vi_insert]
    event: [
      { edit: InsertString, value: "!$" }
      { send: Enter }
    ]
  }
]

$env.config.keybindings ++= [
  {
    name: help_menu
    modifier: none
    keycode: f1
    mode: [emacs, vi_insert, vi_normal]
    event: { send: menu name: help_menu }
  }
]

$env.config.menus ++= [
    {
        name: help_menu
        only_buffer_difference: true
        marker: "? "
        type: {
            layout: description
            columns: 4
            # col_width is an optional value. If missing, the entire screen width is used to
            # calculate the column width
            col_width: 20
            col_padding: 2
            selection_rows: 4
            description_rows: 10
        }
        style: {
            text: green
            selected_text: green_reverse
            description_text: yellow
        }
    }
]

$env.config.color_config = {
    separator: white
    leading_trailing_space_bg: { attr: n }
    header: green_bold
    empty: blue
    bool: light_cyan
    int: white
    filesize: cyan
    duration: white
    datetime: purple
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: green_bold
    record: white
    list: white
    closure: green_bold
    glob:cyan_bold
    block: white
    hints: dark_gray
    search_result: { bg: red fg: white }
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_glob_interpolation: cyan_bold
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
    shape_garbage: {
        fg: white
        bg: red
        attr: b
    }
}

do --env {
  def prompt-header [
    --left-char: string
  ]: nothing -> string {
    let code = $env.LAST_EXIT_CODE

    let jj_workspace_root = try {
      jj workspace root err> $null_device
    } catch {
      ""
    }

    let hostname = if ($env.SSH_CONNECTION? | is-not-empty) {
      let hostname = try {
        hostname
      } catch {
        "remote"
      }

      $"(ansi light_green_bold)@($hostname)(ansi reset) "
    } else {
      ""
    }

    let android_env = if ($env.DEVICE? | is-not-empty) and ($env.TYPE? | is-not-empty) {
      $" (ansi light_purple)\(($env.DEVICE)-($env.TYPE)\)(ansi reset)"
    } else {
      ""
    }

    # https://github.com/nushell/nushell/issues/16205
    #
    # Case insensitive filesystems strike again!
    let pwd = pwd | path expand

    let body = if ($jj_workspace_root | is-not-empty) {
      let subpath = $pwd | path relative-to $jj_workspace_root
      let subpath = if ($subpath | is-not-empty) {
        $"(ansi magenta_bold) → (ansi reset)(ansi blue)($subpath)"
      }

      $"($hostname)(ansi cyan_bold)($jj_workspace_root | path basename)($subpath)(ansi reset)"
    } else {
      let pwd = if ($pwd | str starts-with $env.HOME) {
        "~" | path join ($pwd | path relative-to $env.HOME)
      } else {
        $pwd
      }

      $"($hostname)(ansi cyan)($pwd)(ansi reset)"
    }

    let jj_status = try {
      jj --quiet --color always --ignore-working-copy log --no-graph --revisions @ --template '
        separate(
          " ",
          if(empty, label("empty", "(empty)")),
          coalesce(
            surround(
              "\"",
              "\"",
              if(
                description.first_line().substr(0, 24).starts_with(description.first_line()),
                description.first_line().substr(0, 24),
                description.first_line().substr(0, 23) ++ "…"
              )
            ),
            label(if(empty, "empty"), description_placeholder)
          ),
          bookmarks.join(", "),
          change_id.shortest(),
          commit_id.shortest(),
          if(conflict, label("conflict", "(conflict)")),
          if(divergent, label("divergent prefix", "(divergent)")),
          if(hidden, label("hidden prefix", "(hidden)")),
        )
      ' err> $null_device
    } catch {
      ""
    }

    let jj_info = if ($jj_status | is-empty) {
      ""
    } else {
      $" ($jj_status)"
    }

    let command_duration = ($env.CMD_DURATION_MS | into int) * 1ms
    let command_duration = if $command_duration <= 2sec {
      ""
    } else {
      $"┫(ansi light_magenta_bold)($command_duration)(ansi light_cyan_bold)┣━"
    }

    let exit_code = if $code == 0 {
      ""
    } else {
      $"┫(ansi light_red_bold)($code)(ansi light_cyan_bold)┣━"
    }

    let middle = if $command_duration == "" and $exit_code == "" {
      "━"
    } else {
      ""
    }

    $"(ansi light_cyan_bold)($left_char)($exit_code)($middle)($command_duration)(ansi reset) ($body)($android_env)($jj_info)(char newline)"
  }

  $env.PROMPT_INDICATOR = $"(ansi light_cyan_bold)┃(ansi reset) ";
  $env.PROMPT_INDICATOR_VI_NORMAL = $env.PROMPT_INDICATOR
  $env.PROMPT_INDICATOR_VI_INSERT = $env.PROMPT_INDICATOR
  $env.PROMPT_MULTILINE_INDICATOR = $env.PROMPT_INDICATOR
  $env.PROMPT_COMMAND = {|| prompt-header --left-char "┏" }
  $env.PROMPT_COMMAND_RIGHT = {|| date now | format date "%r" }

  $env.TRANSIENT_PROMPT_INDICATOR = "  "
  $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = $env.TRANSIENT_PROMPT_INDICATOR
  $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = $env.TRANSIENT_PROMPT_INDICATOR
  $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = $env.TRANSIENT_PROMPT_INDICATOR
  $env.TRANSIENT_PROMPT_COMMAND = {|| prompt-header --left-char "━" }
  $env.TRANSIENT_PROMPT_COMMAND_RIGHT = $env.PROMPT_COMMAND_RIGHT
}

let menus = [
  {
    name: completion_menu
    only_buffer_difference: false
    marker: $env.PROMPT_INDICATOR
    type: {
      layout: ide
      min_completion_width: 0
      max_completion_width: 150
      max_completion_height: 25
      padding: 0
      border: false
      cursor_offset: 0
      description_mode: "prefer_right"
      min_description_width: 0
      max_description_width: 50
      max_description_height: 10
      description_offset: 1
      correct_cursor_pos: true
    }
    style: {
      text: green
      selected_text: green_reverse
      description_text: yellow
      match_text: { attr: u }
      selected_match_text: { attr: ur }
    }
  }
  {
    name: history_menu
    only_buffer_difference: true
    marker: $env.PROMPT_INDICATOR
    type: {
      layout: list
      page_size: 10
    }
    style: {
      text: white
      selected_text: white_reverse
    }
  }
]

$env.config.menus = $env.config.menus
| where name not-in ($menus | get name)
| append $menus

# Retrieve the output of the last command.
def _ []: nothing -> any {
  $env.last?
}

# Create a directory and cd into it.
def --env mc [path: path]: nothing -> nothing {
  mkdir $path
  cd $path
}

# Create a directory, cd into it and initialize version control.
def --env mcg [path: path]: nothing -> nothing {
  mkdir $path
  cd $path
  jj git init --colocate
}

def --env "nu-complete jc" [commandline: string] {
  let stor = stor open

  if $stor.jc_completions? == null {
    stor create --table-name jc_completions --columns { value: str, description: str, is_flag: bool }
  }

  if $stor.jc_completions_ran? == null {
    stor create --table-name jc_completions_ran --columns { _: bool }
  }

  if $stor.jc_completions_ran == [] { try {
    let about = ^jc --about
    | from json

    let magic = $about
    | get parsers
    | each { { value: $in.magic_commands?, description: $in.description } }
    | where value != null
    | flatten

    let options = $about
    | get parsers
    | select argument description
    | rename value description

    let inherent = ^jc --help
    | lines
    | split list "" # Group with empty lines as boundary.
    | where { $in.0? == "Options:" } | get 0 # Get the first section that starts with "Options:"
    | skip 1 # Remove header
    | each { str trim }
    | parse "{short},  {long} {description}"
    | update description { str trim }
    | each {|record|
      [[value, description];
        [$record.short, $record.description],
        [$record.long, $record.description],
      ]
    }
    | flatten

    for entry in $magic {
      stor insert --table-name jc_completions --data-record ($entry | insert is_flag false)
    }

    for entry in ($options ++ $inherent) {
      stor insert --table-name jc_completions --data-record ($entry | insert is_flag true)
    }

    stor insert --table-name jc_completions_ran --data-record { _: true }
  } }

  if ($commandline | str contains "-") {
    $stor.jc_completions
  } else {
    $stor.jc_completions
    | where is_flag == 0
  } | select value description
}

# Run `jc` (JSON Converter).
def --wrapped jc [...arguments: string@"nu-complete jc"]: [any -> table, any -> record, any -> string] {
  let run = ^jc ...$arguments | complete

  if $run.exit_code != 0 {
    error make {
      msg: "jc exection failed"
      label: {
        text: ($run.stderr | str replace "jc:" "" | str replace "Error -" "" | str trim)
        span: (metadata $arguments).span
      }
    }
  }

  if "--help" in $arguments or "-h" in $arguments {
    $run.stdout
  } else {
    $run.stdout | from json
  }
}

# Show information about a nix package.
def gist [
  # Any attribute of `pkgs`
  pkg_path: string

  # Show all the metadata
  --long (-l)

  # Open the homepage
  --open (-o)
] {
  let pkg = nix eval --offline --json $"nixpkgs#($pkg_path).meta" | from json

  # Probably because the package doesn't exist. Nix would've printed an error.
  if $pkg == null {
    return
  }

  if $long {
    return $pkg
  }

  if $open {
    start $pkg.homepage
    return $pkg.homepage
  }

  $pkg
    | select name? description? homepage?
    | transpose key value
    | where value != null
    | reduce --fold {} { |row, acc| $acc | merge { $row.key: $row.value } }
}

# Convert a number to different bases.

def bin [num: int] {
	$num | format number | get binary
}

def hex [num: int] {
	$num | format number | get lowerhex
}

def oct [num: int] {
	$num | format number | get octal
}

def set-android-animations [
    scale: float
    --serial (-s): string = "47021FDAS004YA"
] {
    let s = ($scale | into string)
    adb -s $serial shell settings put global window_animation_scale $s
    adb -s $serial shell settings put global transition_animation_scale $s
    adb -s $serial shell settings put global animator_duration_scale $s
}
