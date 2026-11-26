#!/usr/bin/env python3
"""Scan the image tree for CR characters in text/config files.
warsaw's v34 failure: CRLF in system.manifest put a \\r into symlink targets, so
/etc/master.passwd could not be opened and every launchd job exited ENOENT."""
import os, sys

ROOT = "/root/star26/s48/work/root"
EXT = (".plist", ".conf", ".jobs", ".manifest", ".txt", ".sh")
bad = []
scanned = 0
for dirpath, dirnames, filenames in os.walk(ROOT):
    for fn in filenames:
        p = os.path.join(dirpath, fn)
        if not fn.endswith(EXT):
            continue
        try:
            with open(p, "rb") as f:
                d = f.read()
        except Exception:
            continue
        scanned += 1
        if b"\r" in d:
            bad.append((p, d.count(b"\r"), len(d)))

print("scanned %d text/config files" % scanned)
print("files containing CR: %d" % len(bad))
for p, n, sz in bad[:40]:
    print("  CR=%-4d size=%-8d %s" % (n, sz, p))

# also check the binary plists we edited for stray CR in string values
try:
    import plistlib
    for name in ["com.apple.SpringBoard", "com.apple.backboardd", "com.apple.runningboardd"]:
        p = os.path.join(ROOT, "LaunchDaemons", name + ".plist")
        if not os.path.exists(p):
            continue
        d = plistlib.load(open(p, "rb"))
        hits = []
        for k, v in d.items():
            if isinstance(v, str) and "\r" in v:
                hits.append(k)
            if isinstance(v, list):
                for i, x in enumerate(v):
                    if isinstance(x, str) and "\r" in x:
                        hits.append("%s[%d]" % (k, i))
        print("plist %-28s keys with CR: %s" % (name, hits or "none"))
except Exception as e:
    print("plist check skipped:", e)
