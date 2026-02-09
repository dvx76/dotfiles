# Dotfiles

## Install

```
git clone git@github.com:fdevaux/dotfiles.git .dotfiles
cd dotfiles
mkdir -p ~/.config/nvim
stow nvim --target="$HOME/.config/nvim"
stow zsh git tmux vim

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```
