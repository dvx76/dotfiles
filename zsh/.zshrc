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

[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

# Non-zsh stuff

# less -r = keep color
alias less="less -r"

# ls deluxe
if command -v lsd &> /dev/null; then
    alias ls="lsd --color always"
fi

export EDITOR=vim
#export GPG_TTY=$(tty)
export GPG_TTY=$TTY
export PATH="$HOME/.poetry/bin:$HOME/.local/bin:$PATH"

# Load pyenv automatically by appending
# the following to
# ~/.bash_profile if it exists, otherwise ~/.profile (for login shells)
# and ~/.bashrc (for interactive shells) :
#
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Load pyenv-virtualenv automatically by adding
# the following to ~/.bashrc:
#
# eval "$(pyenv virtualenv-init -)"

# FZF Functions
function fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort --preview \
         'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1 ; }; f {}' \
      --header "enter to view, ctrl-o to checkout" \
      --bind "q:abort,ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
      --bind "ctrl-o:become:(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs git checkout)" \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF" --preview-window=right:60%
}

function fsb() {
    local pattern=$*
        local branches branch
        branches=$(git branch --all | awk 'tolower($0) ~ /'"$pattern"'/') &&
        branch=$(echo "$branches" |
                fzf-tmux -p --reverse -1 -0 +m) &&
        if [ "$branch" = "" ]; then
            echo "[$0] No branch matches the provided pattern"; return;
    fi;
    git checkout "$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")"
}

