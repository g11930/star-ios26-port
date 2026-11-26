#!/usr/bin/env python3
# 只读对比：能进桌面的 s208 vs 卡住的 s212，定位解锁机制差异
import re, sys

FILES = {
    "s208-now":  "/mnt/d/ios26/s208-now.bin",
    "s212":      "/mnt/d/ios26/now-041052.bin",
}
MARKERS = [
    "pac_patch=", "autounlock=",
    "sb26: unlock", "boot unlock", "unlockUIFromSource",
    "unlockedEnvironmentMode", "sb26: boot", "activation_installed",
    "software_icons_installed", "sb26: loaded in SpringBoard",
    "render pipelines", "STARL star_display", "userspace panic",
]

def main():
    for label, path in FILES.items():
        print("=" * 60)
        print(label, path)
        try:
            data = open(path, "rb").read()
        except Exception as e:
            print("  OPEN FAIL", e)
            continue
        text = data.decode("utf-8", "replace")
        lines = text.splitlines()
        print("  size", len(data), "lines", len(lines))
        # cmdline
        cmd = ""
        for ln in lines[:400]:
            if ln.startswith("cmdline:"):
                cmd = ln
                break
        for tok in cmd.split():
            if tok.startswith("pac_patch=") or tok.startswith("autounlock="):
                print("  CMDLINE", tok)
        # marker counts
        for m in MARKERS:
            c = text.count(m)
            if c:
                print("  %-34s %d" % (m, c))
        # unlock-related lines context (s208)
        print("  --- unlock lines (first 12) ---")
        n = 0
        for i, ln in enumerate(lines):
            if any(k in ln for k in ("unlockUIFromSource", "unlockedEnvironmentMode", "sb26: unlock", "boot unlock")):
                print("   [%d] %s" % (i + 1, ln[:220]))
                n += 1
                if n >= 12:
                    break

if __name__ == "__main__":
    main()
