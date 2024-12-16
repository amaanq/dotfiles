# Nushell Environment Config File
#
# version = "0.100.0"

# def create_left_prompt [] {
#     let dir = match (do --ignore-shell-errors { $env.PWD | path relative-to $nu.home-path }) {
#         null => $env.PWD
#         '' => '~'
#         $relative_pwd => ([~ $relative_pwd] | path join)
#     }
#
#     let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
#     let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
#     let path_segment = $"($path_color)($dir)(ansi reset)"
#
#     $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
# }

# def create_right_prompt [] {
#     # create a right prompt in magenta with green separators and am/pm underlined
#     let time_segment = ([
#         (ansi reset)
#         (ansi magenta)
#         (date now | format date '%x %X') # try to respect user's locale
#     ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
#         str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")
#
#     let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
#         (ansi rb)
#         ($env.LAST_EXIT_CODE)
#     ] | str join)
#     } else { "" }
#
#     ([$last_exit_code, (char space), $time_segment] | str join)
# }

def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
# $env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }
$env.PROMPT_COMMAND_RIGHT = ""

# The prompt indicators are environmental variables that represent
# the state of the prompt
# $env.PROMPT_INDICATOR = {|| "> " }
# $env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
# $env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
# $env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ": "
$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
$env.PROMPT_MULTILINE_INDICATOR = "::: "

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `🚀`.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions')
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
# An alternate way to add entries to $env.PATH is to use the custom command `path add`
# which is built into the nushell stdlib:
# use std "path add"
# $env.PATH = ($env.PATH | split row (char esep))
# path add /some/path
# path add ($env.CARGO_HOME | path join "bin")
# path add ($env.HOME | path join ".local" "bin")
# $env.PATH = ($env.PATH | uniq)

# To load from a custom file you can use:
# source ($nu.default-config-dir | path join 'custom.nu')

### Environment

$env.EDITOR = "nvim"

$env.RUST_SRC_PATH = $"(^rustc --print sysroot)/lib/rustlib/src/rust/src"

$env.GOPATH = $"($nu.home-path)/.go"

$env.ANDROID_HOME = "/opt/android-sdk"
$env.NDK_HOME = $"($nu.home-path)/Android/Sdk/ndk"
$env.NDK_PATH = $"($env.NDK_HOME)/26.1.10909125"

$env.LG_CONFIG_FILE = $"($nu.home-path)/.config/lazygit/config.yml,($nu.home-path)/.cache/nvim/lazygit-theme.yml"

$env.PATH = ($env.PATH | split row (char esep) | append [
    $"($nu.home-path)/.local/bin"
    $"($nu.home-path)/.local/bin/pnpm"
    $"($nu.home-path)/.cargo/bin"
    $"($nu.home-path)/.bun/bin"
    $"($nu.home-path)/.radicle/bin"
    $"($nu.home-path)/projects/zig"
    $"($nu.home-path)/projects/zig-dev"
    $"($env.GOPATH)/bin"
    $env.NDK_PATH
    "/opt/android-sdk/platform-tools"
])

$env.FZF_DEFAULT_OPTS = [
    "--cycle"
    "--layout=reverse"
    "--height 60%"
    "--ansi"
    "--preview-window=right:90%"
    "--bind=ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-x:jump"
    "--bind=ctrl-f:preview-page-down,ctrl-b:preview-page-up"
    "--bind=ctrl-a:beginning-of-line,ctrl-e:end-of-line"
    "--bind=ctrl-j:down,ctrl-k:up"
] | str join " "

$env.STARSHIP_SHELL = "nu"

zoxide init nushell --cmd=cd | save -f ~/.zoxide.nu
