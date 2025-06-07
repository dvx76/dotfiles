# Dotfiles

## Install

```
git clone git@github.com:fdevaux/dotfiles.git .dotfiles
cd dotfiles
stow */

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```
