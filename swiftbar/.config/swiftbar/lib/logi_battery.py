#!/usr/bin/env python3
"""
Read the battery level of a Logitech Lightspeed (HID++ 2.0) mouse receiver,
e.g. the G 502 X Lightspeed receiver (PID 0xC547).

Talks HID++ 2.0 over the receiver's HID++ interface (usage page 0xFF00),
mirroring the wire format of Solaar (lib/logitech_receiver).

Battery features:
  0x1004 - G502 X implements the *unified battery* layout:
           fn 0x00 = capabilities, fn 0x10 = info [%, level, status].
           (Solaar assumes the legacy fn 0x00 = [level, next, status] layout;
           we prefer fn 0x10 and validate before falling back.)
  0x1010 - unified battery (fn 0x10 info)
  0x1005 - legacy level status (fn 0x00)

Usage:
  logi_battery.py [--watch SECONDS] [--json]
"""

import argparse
import hid
import sys
import time

VID = 0x046D  # Logitech
RECEIVER_PIDS = {
    0xC547: "G 502 X Lightspeed receiver",
    0xC548: "G 502 X receiver (variant)",
    0xC092: "G502 Lightspeed receiver",
}
SW_ID = 0x01  # software id, echoed by the device; lets us match replies to requests

# 0x1004/0x1010 fn 0x10 "get battery info": status enum
STATUS_NAMES = {
    0: "discharging",
    1: "charging",
    2: "charging (slow)",
    3: "full",
    4: "error",
}
# 0x1004/0x1010 fn 0x10: coarse level enum
LEVEL_NAMES = {
    1: "critical",
    2: "low",
    4: "good",
    8: "full",
}


def find_receiver():
    """Return (path, product_name) of the receiver's HID++ interface."""
    for d in hid.enumerate(VID, 0):
        name = RECEIVER_PIDS.get(d["product_id"])
        if name and d["usage_page"] in (0xFF00, 0xFF43):
            return d["path"], name
    return None, None


class HIDPP:
    def __init__(self, dev, devidx):
        self.dev = dev
        self.devidx = devidx

    def _send(self, report_id, feature_idx, function, params=b""):
        payload = bytes([feature_idx, (function & 0xF0) | SW_ID]) + params
        size = 7 if report_id == 0x10 else 20
        msg = bytes([report_id, self.devidx]) + payload
        self.dev.write(msg + b"\x00" * (size - len(msg)))

    def _read_matching(self, feature_idx, function, timeout_ms=500):
        """Read until we get the reply to *our* request (feature index + swid echo)."""
        want = bytes([feature_idx, (function & 0xF0) | SW_ID])
        deadline = time.monotonic() + timeout_ms / 1000
        while time.monotonic() < deadline:
            try:
                data = self.dev.read(64, max(50, int((deadline - time.monotonic()) * 1000)))
            except Exception:
                return None
            if not data:
                continue
            r = bytes(data)
            if len(r) >= 4 and r[1] == self.devidx and r[2:4] == want:
                return r
            if len(r) >= 4 and r[1] == self.devidx and r[3] == 0x8F and r[2] == 0xFF:
                return None  # HID++ 2.0 error reply
        return None

    def feature_index(self, feature_id):
        self._send(0x11, 0x00, 0x00, bytes([(feature_id >> 8) & 0xFF, feature_id & 0xFF]))
        r = self._read_matching(0x00, 0x00)
        if r and len(r) >= 5:
            return r[4]
        return None

    def call(self, feature_idx, function, params=b""):
        self._send(0x11, feature_idx, function, params)
        return self._read_matching(feature_idx, function)

    def battery(self):
        """Returns dict(level, status, level_name, next_day, feature, source) or None."""
        # --- 0x1004: unified-battery layout on G502 X, legacy layout on others ---
        fidx = self.feature_index(0x1004)
        if fidx:
            r = self.call(fidx, 0x10)  # get battery info
            if r and len(r) >= 7 and r[4] <= 100 and r[5] in (1, 2, 4, 8):
                return {
                    "level": r[4],
                    "status": STATUS_NAMES.get(r[6], f"unknown({r[6]:#x})"),
                    "level_name": LEVEL_NAMES.get(r[5]),
                    "next_day": None,
                    "feature": "BATTERY_STATUS",
                    "source": "0x1004 fn1 (unified info)",
                }
            r = self.call(fidx, 0x00)  # legacy layout: [level, next, status]
            if r and len(r) >= 7:
                return {
                    "level": r[4],
                    "status": STATUS_NAMES.get(r[6], f"unknown({r[6]:#x})"),
                    "level_name": None,
                    "next_day": r[5],
                    "feature": "BATTERY_STATUS",
                    "source": "0x1004 fn0 (legacy status)",
                }
        # --- 0x1010: unified battery ---
        fidx = self.feature_index(0x1010)
        if fidx:
            r = self.call(fidx, 0x10)
            if r and len(r) >= 7:
                return {
                    "level": r[4],
                    "status": STATUS_NAMES.get(r[6], f"unknown({r[6]:#x})"),
                    "level_name": LEVEL_NAMES.get(r[5]),
                    "next_day": None,
                    "feature": "UNIFIED_BATTERY",
                    "source": "0x1010 fn1",
                }
        # --- 0x1005: legacy level status ---
        fidx = self.feature_index(0x1005)
        if fidx:
            r = self.call(fidx, 0x00)
            if r and len(r) >= 7:
                status = STATUS_NAMES.get(r[5], f"unknown({r[5]:#x})")
                if status.startswith("unknown"):
                    status = STATUS_NAMES.get(r[6], status)
                return {
                    "level": r[4],
                    "status": status,
                    "level_name": None,
                    "next_day": None,
                    "feature": "BATTERY_LEVEL_STATUS",
                    "source": "0x1005 fn0",
                }
        return None


def main():
    ap = argparse.ArgumentParser(description="Read Logitech Lightspeed mouse battery")
    ap.add_argument("--watch", type=float, metavar="SECONDS", help="poll continuously")
    ap.add_argument("--json", action="store_true", help="output JSON")
    args = ap.parse_args()

    path, name = find_receiver()
    if path is None:
        print("No Logitech Lightspeed receiver found. Is the dongle plugged in?", file=sys.stderr)
        sys.exit(1)

    dev = hid.device()
    dev.open_path(path)

    pp, devidx = None, None
    for idx in range(1, 7):
        pp = HIDPP(dev, idx)
        d = pp.battery()
        if d and d["level"] is not None:
            devidx = idx
            break
        time.sleep(0.1)

    if devidx is None:
        dev.close()
        print("No response from the mouse. Move/wiggle the mouse to wake it, then retry.", file=sys.stderr)
        sys.exit(2)

    def report(prev=None):
        d = pp.battery()
        if d is None:
            d = prev or {"level": None}
        d["device"] = name
        d["device_index"] = devidx
        if args.json:
            import json
            print(json.dumps(d, ensure_ascii=False))
        else:
            print(f"Device : {name} (index {devidx}) | {d.get('feature')}")
            if d["level"] is None:
                print("Battery: <no response>")
            else:
                extra = f" ({d['level_name']})" if d.get("level_name") else ""
                print(f"Battery: {d['level']}% — {d['status']}{extra}")
                if d.get("next_day"):
                    print(f"Next-day drain: ~{d['next_day']}%")
                print(f"Source : {d.get('source')}")
        return d

    report()
    if args.watch:
        prev = None
        try:
            while True:
                time.sleep(args.watch)
                prev = report(prev)
        except KeyboardInterrupt:
            pass
    dev.close()


if __name__ == "__main__":
    main()