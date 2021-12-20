# export ZSH="/home/fdevaux/.oh-my-zsh"
export ZSH="${HOME}/.oh-my-zsh"

# ZSH_THEME="robbyrussell"
ZSH_THEME="agnoster"

# zstyle ':omz:update' mode disabled  # disable automatic updates

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

export EDITOR=vim
export PATH=$PATH:/usr/local/go/bin
export GPG_TTY=$(tty)
