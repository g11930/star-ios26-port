#!/usr/bin/env python3
# 一锤定音：对比 GOOD(进桌面) 与 BAD(回滚没进) 里 sb26 激活 hook 的安装结果
import re
FILES = {
    "GOOD 02:26 进桌面": "/mnt/c/ios26/s208-now.bin",
    "BAD 05:48 没进": "/mnt/c/ios26/now-054802.bin",
}
KEYS = ["sb26: validate _setupActivationState",
        "activation_installed", "activation call",
        "sb26: loaded", "build=23G90", "build mismatch",
        "skipped invalid shared cache", "validate unlockUIFromSource",
        "unlockUIFromSource:withOptions:",
        "unlock boot", "sb26: unlock",
        "MKB_INIT", "could not open"]
for label, p in FILES.items():
    print("=" * 78)
    print(label, p)
    d = open(p, "rb").read().decode("utf-8", "replace")
    for k in KEYS:
        hits = [l.strip() for l in d.splitlines() if k in l]
        print("  %-38s %d" % (k, len(hits)))
        for h in hits[:4]:
            print("      ", h[:190])
