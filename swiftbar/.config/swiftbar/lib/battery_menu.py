# /// script
# requires-python = ">=3.11"
# dependencies = ["hidapi>=0.14"]
# ///
"""Wireless mouse/keyboard battery in the SwiftBar menu bar.

Usage: battery_menu.py mouse|keyboard
Run through `uv run --script` (see plugins/logi-*.sh) so hidapi is installed
automatically on a fresh machine.

  mouse    -> logi_battery.py: HID++ through a Logitech Lightspeed receiver
              (G 502 X and friends).
  keyboard -> bt_battery.py: the battery macOS reports for a Bluetooth
              keyboard. Set BT_KEYBOARD_MATCH to a substring of the device
              name (default "NuPhy").

NOTE for the NuPhy Air75 V2: System Settings shows this keyboard's battery
(read over macOS's private Bluetooth settings channel), but macOS exposes it to
no other app: ioreg, system_profiler, HID feature reports and the HID input
stream carry no battery data (verified 2026-09-13). Its icon therefore stays at
"?"; press FN+B on the keyboard to check battery.
"""

import datetime
import json
import os
import subprocess
import sys
from pathlib import Path

LIB = Path(__file__).resolve().parent

READERS = {
    "mouse": [sys.executable, str(LIB / "logi_battery.py"), "--json"],
    "keyboard": [sys.executable, str(LIB / "bt_battery.py"), "--json",
                 "--match", os.environ.get("BT_KEYBOARD_MATCH", "NuPhy")],
}
SYMBOLS = {"mouse": "computermouse", "keyboard": "keyboard"}
HINTS = {
    "mouse": "Move the mouse to wake it, or check the receiver.",
    "keyboard": "macOS shows this keyboard's battery only inside System Settings — "
                "no public API exposes it to menu bar apps. Press FN+B on the keyboard to see it.",
}
CHARGING = {"charging", "charging (slow)", "full"}


def read_battery(kind):
    try:
        out = subprocess.run(READERS[kind], capture_output=True, text=True, timeout=25)
        if out.returncode == 0 and out.stdout.strip():
            data = json.loads(out.stdout.strip().splitlines()[-1])
            if data.get("level") is not None:
                return data
    except Exception:
        pass
    return None


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in READERS else "mouse"
    data = read_battery(kind)
    checked = datetime.datetime.now().strftime("%H:%M")
    symbol = SYMBOLS[kind]
    device_label = (data or {}).get("device") or "Wireless device"

    if data is None:
        print(f"? | sfimage={symbol} color=gray sfcolor=gray tooltip=\"{device_label} battery\"")
        print("---")
        print("No battery reading right now")
        print(HINTS[kind])
        print(f"Checked: {checked}")
        print("---")
        print("↻ Retry now | refresh=true")
        return

    level = data["level"]
    status = data.get("status") or "unknown"

    if level <= 20:
        color = "red"
    elif level <= 50:
        color = "orange"
    else:
        color = None

    title = f"{level}%"
    params = [f"sfimage={symbol}", f'tooltip="{device_label} battery"']
    if status in CHARGING:
        title += " ⚡"
    if color:
        params += [f"color={color}", f"sfcolor={color}"]
    print(title + " | " + " ".join(params))

    print("---")
    print(f"{device_label} | size=12")
    print(f"Battery: {level}%")
    if status != "unknown":
        print(f"Status: {status}")
    if data.get("level_name"):
        print(f"Level: {data['level_name']}")
    if data.get("source"):
        print(f"Source: {data['source']}")
    print(f"Checked: {checked}")
    print("---")
    print("↻ Refresh now | refresh=true")


if __name__ == "__main__":
    main()
