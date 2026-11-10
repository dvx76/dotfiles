#!/bin/bash
# <swiftbar.title>Keyboard battery</swiftbar.title>
# <swiftbar.desc>Bluetooth keyboard battery as macOS reports it.</swiftbar.desc>
# Logic lives in ../lib/battery_menu.py; uv installs its Python dependencies.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
lib="$HOME/.config/swiftbar/lib"
if ! command -v uv >/dev/null; then
  echo "? | sfimage=keyboard color=gray sfcolor=gray"
  echo "---"
  echo "uv not found: brew install uv"
  exit 0
fi
exec uv run --quiet --script "$lib/battery_menu.py" keyboard
