#!/usr/bin/env python3
# 只读：分析 s212 更晚的日志，确认长时间运行后是否解锁 / 卡在哪
import re

FILES = [
    "/mnt/d/ios26/now-042429.bin",
    "/mnt/d/ios26/now-042536.bin",
]
UNLOCK = ["unlockedEnvironmentMode", "unlockUIFromSource", "sb26: unlock", "boot unlock",
          "unlock notification", "activation_installed", "iconfill scheduled"]
PANIC  = ["userspace panic", "non-platform", "KERNEL FAULT", "haltRestart", "PANIC caller"]
PROG   = ["SystemShell", "render pipelines", "swap#", "SpringBoard[", "statusbar", "PosterBoard"]

def wallclock(lines):
    first = last = ""
    for ln in lines:
        m = re.match(r"(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)", ln)
        if m:
            if not first: first = m.group(1)
            last = m.group(1)
    return first, last

def main():
    for path in FILES:
        print("=" * 66)
        print(path)
        try:
            lines = open(path, "rb").read().decode("utf-8", "replace").splitlines()
        except Exception as e:
            print("  OPEN FAIL", e); continue
        print("  lines", len(lines))
        f, l = wallclock(lines)
        print("  wallclock first=%s last=%s" % (f, l))
        text = "\n".join(lines)
        for tag, keys in (("UNLOCK", UNLOCK), ("PANIC", PANIC), ("PROGRESS", PROG)):
            print("  --- %s ---" % tag)
            for k in keys:
                c = text.count(k)
                print("    %-28s %d" % (k, c))
        # pac counters last
        pac = [ln for ln in lines if "pac: traps=" in ln]
        print("  --- last pac counter ---")
        print("   ", pac[-1].strip() if pac else "(none)")
        # last 15 meaningful lines
        print("  --- tail ---")
        for ln in lines[-15:]:
            print("   ", ln[:200])

if __name__ == "__main__":
    main()
