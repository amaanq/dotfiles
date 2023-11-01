if ! pgrep -u "$USER" gpg-agent > /dev/null; then
    gpg-agent --daemon
fi

# Set GPG TTY to ensure pinentry is displayed properly in all terminals
GPG_TTY=$(tty)
export GPG_TTY

eval `keychain --eval --agents ssh id_ed25519`
if [ $? -ne 0 ]; then
	echo "Make an ed25519 key ASAP! (keychain failed)"
fi

eval "$(starship init zsh --print-full-init)"

export DENO_INSTALL="$HOME/.deno"

export EDITOR="nvim"

export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

export ANDROID_HOME="/opt/android-sdk"
export NDK_HOME="/home/amaanq/Android/Sdk/ndk"
export NDK_PATH="$NDK_HOME/25.2.9519653"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.local/bin/pnpm"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/projects/zig"
export PATH="$PATH:$HOME/projects/zig-dev"
export PATH="$PATH:$DENO_INSTALL/bin"
export PATH="$PATH:$HOME/.surrealdb"
export PATH="$PATH:$NDK_PATH"
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
export PATH="/opt/android-sdk/platform-tools:$PATH"
if [[ ":$LD_LIBRARY_PATH:" != *":/usr/lib:"* ]]; then
	# check if its empty to append (it can exist but be empty)
	if [ -z "$LD_LIBRARY_PATH" ]; then
		export LD_LIBRARY_PATH="/usr/lib"
	else
		export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
	fi
fi
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
if [[ ":$PKG_CONFIG_PATH:" != *":/usr/lib:"* ]]; then
	if [ -z "$PKG_CONFIG_PATH" ]; then
		export PKG_CONFIG_PATH="/usr/lib"
	else
		export PKG_CONFIG_PATH="/usr/lib:$PKG_CONFIG_PATH"
	fi
fi
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig"

if [ ! -f "$HOME/go/bin/gofumpt" ]; then
	go install mvdan.cc/gofumpt@latest
fi
if [ ! -f "$HOME/go/bin/revive" ]; then
	go install github.com/mgechev/revive@latest
fi

source $HOME/.cargo/env
if [ ! -f "$HOME/.config/rustlang/autocomplete/rustup" ]; then
	mkdir -p ~/.config/rustlang/autocomplete
	rustup completions zsh rustup >> ~/.config/rustlang/autocomplete/rustup
fi
# source "$HOME/.config/rustlang/autocomplete/rustup"

if ! cargo audit --version &> /dev/null; then
	cargo install cargo-audit --features=fix
fi

if ! cargo nextest --version &> /dev/null; then
	cargo install cargo-nextest
fi

if ! cargo fmt --version &> /dev/null; then
	rustup component add rustfmt
fi

if ! cargo clippy --version &> /dev/null; then
	rustup component add clippy
fi

if ! ls ~/.cargo/bin | grep 'cargo-upgrade' &> /dev/null; then
	cargo install cargo-edit
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	colored-man-pages
	git
	jsontools
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

batdiff() {
	git diff --name-only --relative --diff-filter=d | xargs bat --diff
}

dclear() {
	docker ps -a -q | xargs docker kill -f
	docker ps -a -q | xargs docker rm -f
	docker images | awk '{print $3}' | xargs docker rmi -f
	docker volume prune -f
}

note() {
	echo "date: $(date)" >> $HOME/drafts.txt
	echo "$@" >> $HOME/drafts.txt
	echo "" >> $HOME/drafts.txt
}

take() {
	mkdir -p $1
	cd $1
}

if [[ $(ps --no-header -p $PPID -o comm | grep -Ev '^(yakuake|konsole|kitty)$' ) ]]; then
		for wid in $(xdotool search --pid $PPID); do
			xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id $wid; done
fi

alias c="clear"
alias nv="nvim"
alias vi="nvim"
alias lg="lazygit"
alias l="eza -lah"
alias ls=eza
alias sl=eza
alias ts="tree-sitter"
alias tsa="tree-sitter-alpha"
alias tsg="tree-sitter-og g"
alias tsgr="tree-sitter-og g --report-states-for-rule"
alias tsgra="tree-sitter-og g --report-states-for-rule -"
alias trim="awk '{\$1=\$1;print}'"

source ~/.iommu

# opam configuration
[[ ! -r /home/amaanq/.opam/opam-init/init.zsh ]] || source /home/amaanq/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

# pnpm
export PNPM_HOME="/home/amaanq/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export QSYS_ROOTDIR="/home/amaanq/.cache/paru/clone/quartus-free/pkg/quartus-free-quartus/opt/intelFPGA/21.1/quartus/sopc_builder/bin"

# bun completions
[ -s "/home/amaanq/.bun/_bun" ] && source "/home/amaanq/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

stm32env() {
    if [[ $PWD == *Microprocessor* ]]; then
		export PATH="/opt/stm32cubeide/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.11.3.rel1.linux64_1.1.1.202309131626/tools/bin/:$PATH"
        echo "STM32 Environment activated!"
    else
        echo "Not inside STM32CubeIDE directory!"
    fi
}

function stm32deactivate() {
    export PATH=$(echo $PATH | sed -e 's@:/opt/stm32cubeide/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.11.3.rel1.linux64_1.1.1.202309131626/tools/bin@@')
    echo "STM32 Environment deactivated!"
}
