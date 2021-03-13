# dotfiles

## Install

```
git clone git@github.com:fdevaux/dotfiles.git ~/.dotfiles

ln -s ~/.dotfiles/.gitconfig  ~/.gitconfig
ln -s ~/.dotfiles/.vimrc  ~/.vimrc
ln -s ~/.dotfiles/.tmux.conf  ~/.tmux.conf

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```
