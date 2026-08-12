# Dotfiles

## Install

```
sudo apt install stow
# sudo dnf install stow

git clone git@gitlab.com:dvx76/dotfiles.git .dotfiles
cd .dotfiles
mkdir -p ~/.config/nvim
stow nvim --target="$HOME/.config/nvim"
stow zsh git tmux vim

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```
