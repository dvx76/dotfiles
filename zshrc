# export ZSH="/home/fdevaux/.oh-my-zsh"
export ZSH="${HOME}/.oh-my-zsh"

# Debug slowness. Run zprof command
# zmodload zsh/zprof

# ZSH_THEME="robbyrussell"
ZSH_THEME="agnoster"

# zstyle ':omz:update' mode disabled  # disable automatic updates

plugins=(git pass docker zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

if [[ -f "${HOME}/.zshrc.local" ]]; then
  source ${HOME}/.zshrc.local
fi

export EDITOR=vim
export PATH=$PATH:/usr/local/go/bin
export GPG_TTY=$(tty)

# pyenv
# slow?
eval "$(pyenv init --path)"
#eval "$(pyenv virtualenv-init -)"

unsetopt share_history

PROMPT="$PROMPT$ "

export PATH="$HOME/.poetry/bin:$PATH"
