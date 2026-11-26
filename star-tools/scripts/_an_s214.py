#!/usr/bin/env python3
# 只读：s214 判据分析，对比 s212。用法 python3 _an_s214.py <logfile>
import re, sys, glob, os

def analyze(path):
    raw = open(path, "rb").read()
    text = raw.decode("utf-8", "replace")
    lines = text.splitlines()
    print("=" * 68)
    print(path, "size", len(raw), "lines", len(lines))
    # wallclock
    wc = []
    for ln in lines:
        m = re.match(r"(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)", ln)
        if m: wc.append(m.group(1))
    print("wallclock:", wc[0] if wc else "-", "->", wc[-1] if wc else "-")

    # ---- unlock markers (核心判据) ----
    print("--- UNLOCK markers ---")
    for k in ("unlockUIFromSource", "unlockedEnvironmentMode", "sb26: unlock", "boot unlock",
              "activation_installed", "software_icons_installed", "SystemShell", "swap#"):
        print("  %-28s %d" % (k, text.count(k)))
    # any unlock line context
    ul = [ln for ln in lines if "unlockUIFromSource" in ln or "unlockedEnvironmentMode" in ln]
    for ln in ul[:5]:
        print("   UL>", ln[:200])

    # ---- panic ----
    print("--- PANIC markers ---")
    for k in ("userspace panic", "non-platform", "KERNEL FAULT", "haltRestart", "PANIC caller", "panic(cpu"):
        c = text.count(k)
        if c: print("  %-24s %d" % (k, c))
    panic_total = sum(text.count(k) for k in ("userspace panic","non-platform","KERNEL FAULT","PANIC caller","panic(cpu"))
    print("  PANIC_TOTAL =", panic_total)

    # ---- PAC rewrite stats (last counter) ----
    print("--- PAC stats ---")
    pac = [ln for ln in lines if "pac: traps=" in ln]
    print("  last:", pac[-1].strip() if pac else "(none)")
    pg = [ln for ln in lines if "pac: page " in ln]
    print("  page-log lines:", len(pg))
    for ln in pg[:3]: print("   ", ln.strip()[:100])

    # ---- progress / render ----
    print("--- PROGRESS ---")
    for k in ("render pipelines", "SpringBoard[", "backboardd", "PosterBoard", "Metal", "THE GPU STAYS"):
        print("  %-24s %d" % (k, text.count(k)))

    # ---- verdict ----
    has_unlock = text.count("unlockUIFromSource") > 0 and text.count("unlockedEnvironmentMode") > 0
    print("--- VERDICT ---")
    print("  desktop_unlock =", "YES" if has_unlock else "NO", "| panic =", panic_total)

if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        args = sorted(glob.glob("/mnt/c/ios26/s214-*.bin"))
    for p in args:
        if os.path.exists(p): analyze(p)
        else: print("missing", p)
