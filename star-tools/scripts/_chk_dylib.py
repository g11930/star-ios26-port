#!/usr/bin/env python3
import os
paths = {
    "star-obj": "/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib",
    "K90-v013": "/mnt/d/桌面/star26-deps/release/hackios-k90-v0.1.3/root/lib/libannibale-sb26.dylib",
}
markers = [
    "waiting for the lock screen's layout",
    "layout element",
    "appearState",
    "occlusion reasons",
    "boot unlock done",
    "activation call",
    "activation_installed",
    "unlockUIFromSource:withOptions:",
    "coverSheetSlidingViewController",
    "unlock %s: answer",
]
for name, p in paths.items():
    print("=" * 70)
    print(name, p)
    if not os.path.exists(p):
        print("  MISSING")
        continue
    d = open(p, "rb").read()
    st = os.stat(p)
    import datetime
    print("  size=%d  mtime=%s" % (len(d), datetime.datetime.fromtimestamp(st.st_mtime)))
    for m in markers:
        print("  %-42s %d" % (m, d.count(m.encode())))
