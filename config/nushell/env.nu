# Nushell Environment Config File
#
# version = "0.99.0"

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

# def create_right_prompt [] {
#     starship prompt --right --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
# }

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
# FIXME: This default is not implemented in rust code as of 2023-09-08.
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
    ($nu.data-dir | path join 'completions') # default home for nushell completions
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

$env.RUST_SRC_PATH = (echo [(rustc --print sysroot) "/lib/rustlib/src/rust/src"] | str join)

$env.GOPATH = "~/.go"

$env.ANDROID_HOME = "/opt/android-sdk"
$env.NDK_HOME = "~/Android/Sdk/ndk"
$env.NDK_PATH = $"($env.NDK_HOME)/26.1.10909125"

$env.LG_CONFIG_FILE = "/home/amaanq/.config/lazygit/config.yml,/home/amaanq/.cache/nvim/lazygit-theme.yml"

$env.PATH = ($env.PATH | split row (char esep) | append [
    "~/.local/bin"
    "~/.local/bin/pnpm"
    "~/.cargo/bin"
    $"($env.GOPATH)/bin"
    "~/projects/zig"
    "~/projects/zig-dev"
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

### Sources

source ~/.zoxide.nu

### Aliases

alias c = clear
alias q = exit
alias nv = nvim
alias vi = nvim
alias lg = ^TERM=xterm-256color lazygit
alias py = python
alias l = eza -lah
alias ts = tree-sitter
alias trim = ^awk '{\$1=\$1;print}'
alias cd = z

### Functions

# Initialize keychain for SSH key management
def --env setup-keychain [] {
    let output = (keychain --eval --agents ssh id_ed25519 | lines)
    for line in $output {
        let parts = ($line | split row '=' | each { str trim })
        if ($parts | length) >= 2 {
            let key = $parts.0
            let value = ($parts | skip 1 | str join '=')
            load-env { $key: $value }
        }
    }
}

# Initialize GPG agent
def setup-gpg [] {
    if not (ps | where name =~ 'gpg-agent' | is-empty) {
        gpg-agent --daemon
    }
    $env.GPG_TTY = (tty)
}

# Add a note to a file
def --env note [...args] {
    let note_text = ($args | str join " ")
    let date = (date now | format date "%Y-%m-%d %H:%M:%S")
    echo $"date: ($date)\n($note_text)\n" | save --append ~/drafts.txt
}

# Make a directory and cd into it
def take [dirname: string] {
    mkdir $dirname
    cd $dirname
}

# Diff with bat
def batdiff [] {
    git diff --name-only --relative --diff-filter=d
    | lines
    | each { |it| bat --diff $it }
}

# Clear all docker containers and images
def dclear [] {
    docker ps -a -q | each { |id| docker kill -f $id }
    docker ps -a -q | each { |id| docker rm -f $id }
    docker images | from ssv | each { |img| docker rmi -f $img.ID }
    docker volume prune -f
}

# Check if a Go command exists, and install it if it doesn't
def check_go_commands [] {
    if not ("gofumpt" | path exists) {
        go install mvdan.cc/gofumpt@latest
    }
    if not ("revive" | path exists) {
        go install github.com/mgechev/revive@latest
    }
}

# Check if a Rust command exists, and install it if it doesn't
def check_cargo_commands [] {
    if (do { cargo audit --version } | complete).exit_code != 0 {
        cargo install cargo-audit --features=fix
    }
    if (do { cargo nextest --version } | complete).exit_code != 0 {
        cargo install cargo-nextest
    }
    if (do { cargo fmt --version } | complete).exit_code != 0 {
        rustup component add rustfmt
    }
    if (do { cargo clippy --version } | complete).exit_code != 0 {
        rustup component add clippy
    }
    if not (ls ~/.cargo/bin | find cargo-upgrade | is-empty) {
        cargo install cargo-edit
    }
}

# Setup env for STM32 development
def stm32env [] {
    if ($env.PWD | str contains "Microprocessor") {
        $env.PATH = ($env.PATH | split row (char esep) | append [
            "/opt/stm32cubeide/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.11.3.rel1.linux64_1.1.1.202309131626/tools/bin"
        ])
        echo "STM32 Environment activated!"
    } else {
        echo "Not inside STM32CubeIDE directory!"
    }
}

# Deactivate STM32 environment
def stm32deactivate [] {
    $env.PATH = ($env.PATH | split row (char esep) 
        | where { |it| not ($it | str contains "stm32cubeide") } 
        | str join (char esep))
    echo "STM32 Environment deactivated!"
}

def create_startup [] {
    setup-gpg
    setup-keychain
}

# Run startup on shell initialization
create_startup
