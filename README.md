# Dotfiles

## Install

```
git clone git@github.com:fdevaux/dotfiles.git .dotfiles
cd dotfiles
stow */

cd .config/zsh
ln -s ~/.zshrc .zshrc

p10k configure

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```
