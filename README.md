# Dotfiles

## Install

```
sudo apt install stow
# sudo dnf install stow

git clone git@gitlab.com:dvx76/dotfiles.git .dotfiles
cd .dotfiles
stow zsh git tmux vim rex
stow --no-folding nvim worktrunk herdr claude
stow --no-folding swiftbar   # macOS only

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

## Rex

The `rex` package links the whole `~/.config/rex` directory (no
`--no-folding`), since Rex keeps its runtime state elsewhere. It holds
`init.lua` and the `bin/project-picker` script it launches (bound to
`cmd+shift+o`). The picker requires `fzf` and `jq`, and looks for git repos
under `$PROJECTS_ROOT` (default `~/dev`).

## SwiftBar (macOS)

The `swiftbar` package manages the SwiftBar plugins in
`~/.config/swiftbar/plugins` plus their helpers in `bin/` and `lib/`. Use
`--no-folding` so anything built or cached at runtime stays outside the repo.
SwiftBar stores its plugin folder in its own preferences, so point it there
once:

```
brew install --cask swiftbar
brew install jq uv
defaults write com.ameba.SwiftBar PluginDirectory ~/.config/swiftbar/plugins
```

- `claude-usage.2m.sh`: Claude 5-hour and weekly usage, colored by level, with
  time to reset. It reads Claude Code's login from the keychain (nothing is
  stored in the repo) and calls the same undocumented endpoint as `/usage`, so
  log in to Claude Code first. It falls back to the cache the status line
  script writes. The colored title is drawn by `bin/menubar-text`, compiled
  from `menubar-text.swift` on first run (needs `swiftc`, e.g. from
  `xcode-select --install`).
- `logi-battery.10m.sh` / `logi-keyboard.10m.sh`: Logitech Lightspeed mouse
  (HID++) and Bluetooth keyboard battery. They run `lib/battery_menu.py` with
  `uv`, which installs `hidapi` on first run. Set `BT_KEYBOARD_MATCH` to match
  a keyboard other than the default `NuPhy`.
- `bluetooth_inspector.10m.rb`, `mtop.5s.sh`, `zoom*.1s.scpt`: third-party
  plugins, using the system Ruby, bash and osascript.

