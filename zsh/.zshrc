# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# .zshrc
# Inspiration and sources:
# - https://github.com/Mach-OS/Machfile

export ZDOTDIR=$HOME/.config/zsh

# Debug slowness. Run zprof command
# zmodload zsh/zprof

# Functions
function zsh_add_file() {
    [ -f "$ZDOTDIR/$1" ] && source "$ZDOTDIR/$1"
}

function zsh_add_plugin() {
    PLUGIN_NAME=$(echo $1 | cut -d "/" -f 2)
    PLUGIN_SCRIPT=$2
    if [ ! -d "$ZDOTDIR/plugins/$PLUGIN_NAME" ]; then
        git clone "https://github.com/$1.git" "$ZDOTDIR/plugins/$PLUGIN_NAME"
    fi
    if [ ! -z "$PLUGIN_SCRIPT" ]; then
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_SCRIPT"
    else
        # For plugins
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.plugin.zsh" || \
        zsh_add_file "plugins/$PLUGIN_NAME/$PLUGIN_NAME.zsh"
    fi
}

autoload -U compinit && compinit

# History
HISTSIZE=1000
SAVEHIST=1000
mkdir -p $HOME/.cache/zsh
HISTFILE=$HOME/.cache/zsh/history

# Plugins (zsh-syntax-highlighting must be last)
zsh_add_plugin "romkatv/powerlevel10k" "powerlevel10k.zsh-theme"
# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "joshskidmore/zsh-fzf-history-search"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"

export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# CTRL-Left/Right
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
# Replaced by zsh-fzf-history-search if fzf is installed
fzf --version >/dev/null 2>&1 || bindkey "^R" history-incremental-search-backward

[[ ! -f ~/.config/.zshrc.local ]] || source ~/.zshrc.local

# Non-zsh stuff

# ls deluxe
if command -v lsd &> /dev/null; then
    alias ls="lsd -l"
fi

export EDITOR=vim
#export GPG_TTY=$(tty)
export GPG_TTY=$TTY
export PATH="$HOME/.poetry/bin:$PATH"

