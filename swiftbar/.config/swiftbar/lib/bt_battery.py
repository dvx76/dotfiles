#!/usr/bin/env python3
"""
Battery level of a Bluetooth HID device (e.g. NuPhy Air75 V2 keyboard),
from macOS's own Bluetooth power source — the same value System Settings /
Control Center show for connected BT peripherals. No HID++ involved.

Sources, fastest first:
  1. ioreg  -c AppleDeviceManagementHIDEventService   (key "BatteryPercent")
  2. ioreg  -c IOBluetoothHIDDriver                   (key "BatteryPercent")
  3. system_profiler SPBluetoothDataType              ("Battery Level: NN%")

BLE keyboards only report battery while awake/connected, so the level is not
always available -> level is null in that case.

Usage:
  bt_battery.py [--json] [--match NuPhy]
"""

import argparse
import json
import re
import subprocess
import sys

HEADERS = {"Bluetooth:", "Connected:", "Not Connected:"}


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=20).stdout
    except Exception:
        return ""


def _matches(name, match):
    return name is not None and match.lower() in name.lower()


def _ioreg_battery(match, klass):
    """Return (device_name, percent) found in one ioreg service class dump."""
    out = run(["/usr/sbin/ioreg", "-r", "-c", klass, "-l"])
    if not out:
        return None, None
    cur_product, cur_percent = None, None
    for line in out.splitlines():
        m = re.search(r'"Product" = "([^"]*)"', line)
        if m:
            if _matches(cur_product, match) and cur_percent is not None:
                return cur_product, cur_percent
            cur_product, cur_percent = m.group(1), None
            continue
        m = re.search(r'"BatteryPercent" = (\d+)', line)
        if m:
            cur_percent = int(m.group(1))
    if _matches(cur_product, match) and cur_percent is not None:
        return cur_product, cur_percent
    return None, None


def _sp_battery(match):
    """Return (device_name, percent) parsed from system_profiler output."""
    out = run(["system_profiler", "SPBluetoothDataType"])
    lines = out.splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"^\s+([^:]+):\s*$", line)
        if not m or m.group(1) in HEADERS or not _matches(m.group(1), match):
            continue
        percent = None
        for j in range(i + 1, len(lines)):
            nxt = lines[j]
            if not nxt.startswith(" " * 12):
                break
            mm = re.match(r"^\s*Battery Level:\s*(\d+)%", nxt)
            if mm:
                percent = int(mm.group(1))
        return m.group(1), percent
    return None, None


def main():
    ap = argparse.ArgumentParser(description="Bluetooth HID device battery")
    ap.add_argument("--match", default="NuPhy", help="substring of the device name")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    name, level, source = None, None, None
    for klass in ("AppleDeviceManagementHIDEventService", "IOBluetoothHIDDriver"):
        name, level = _ioreg_battery(args.match, klass)
        if level is not None:
            source = f"ioreg {klass}"
            break
    if level is None:
        name, level = _sp_battery(args.match)
        source = "system_profiler SPBluetoothDataType" if level is not None else None

    result = {
        "device": name,
        "level": level,
        "charging": None,  # not reported over the stock Bluetooth API
        "source": source,
        "feature": "Bluetooth HID battery",
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False))
    else:
        if level is None:
            print(f"Device : {args.match}*")
            print("Battery: <not reporting — keyboard asleep or not connected>")
        else:
            print(f"Device : {name}")
            print(f"Battery: {level}%")
            print(f"Source : {source}")
    sys.exit(0 if level is not None else 3)


if __name__ == "__main__":
    main()