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

# Spaceship prompt. Replaced by zsh_add_plugin
#fpath=( "${ZDOTDIR}/functions" $fpath )
#autoload -U promptinit && promptinit
#prompt spaceship

# History 
HISTSIZE=1000
SAVEHIST=1000
mkdir -p $HOME/.cache/zsh
HISTFILE=$HOME/.cache/zsh/history

# Plugins (zsh-syntax-highlighting must be last)
zsh_add_plugin "spaceship-prompt/spaceship-prompt" "spaceship.zsh"
zsh_add_plugin "zsh-users/zsh-autosuggestions"
zsh_add_plugin "zsh-users/zsh-syntax-highlighting"

export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# Non-zsh stuff
export EDITOR=vim
export GPG_TTY=$(tty)
export PATH="$HOME/.poetry/bin:$PATH"
