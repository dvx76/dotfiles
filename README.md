# Dotfiles

## Install

```
sudo apt install stow
# sudo dnf install stow

git clone git@gitlab.com:dvx76/dotfiles.git .dotfiles
cd .dotfiles
mkdir -p ~/.config/nvim ~/.config/worktrunk
stow nvim --target="$HOME/.config/nvim"
stow worktrunk --target="$HOME/.config/worktrunk"
stow zsh git tmux vim
stow --no-folding herdr

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```

Only Worktrunk's `config.toml` is managed here; approvals and other local state
remain outside the repo. Its Python setup hook requires `uv` and the local
`~/.config/env/uv-artifacthub.env` file, which is not tracked.

## Herdr

The `herdr` package manages `~/.config/herdr/config.toml` and the Worktrunk
plugin settings. Use `--no-folding` to link individual files, keeping runtime
state and downloaded plugins outside the repo. Back up any existing files at
those paths before running Stow.

The key bindings also require `~/.local/bin/herdr-agent-picker.sh`, the
`devashish2203/herdr-worktrunk` plugin, and the local `mr-worktree` plugin.
Install those separately; the machine-specific plugin registry, sessions,
logs, and downloaded plugins are not tracked.
