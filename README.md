# Dotfiles

## Install

```
sudo apt install stow
# sudo dnf install stow

git clone git@gitlab.com:dvx76/dotfiles.git .dotfiles
cd .dotfiles
stow zsh git tmux vim
stow --no-folding nvim worktrunk herdr claude

cat > ~/.gitconfig.local <<EOF
[user]
        name = ...
        email = ...
EOF
```

All packages mirror paths under `$HOME`, so no explicit Stow target is needed.
Use `--no-folding` for the `.config` packages to keep runtime state outside the
repo. Back up any existing config files at those paths before running Stow.

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

## Claude Code

The `claude` package manages `~/.claude/settings.json` and the status line
script. Always use `--no-folding`: without it, on a fresh machine Stow would
link `~/.claude` itself into the repo along with all of Claude's runtime state.

Paths use `$HOME`, and hooks for optional tools (herdr, rex, tldraw) do nothing
when the tool is not installed. Skills are not tracked: third-party skills are
installed per machine with `npx skills`, and app-provided skills (rex, tldraw)
come from their apps. Claude Code writes some settings (e.g. `/effort`) back
to `settings.json`, so review those diffs before committing.
