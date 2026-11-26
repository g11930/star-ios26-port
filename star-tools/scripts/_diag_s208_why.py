#!/usr/bin/env python3
# 深挖：s208-now(曾进桌面) vs 回滚后 now-054802(没进桌面)，激活/解锁链路到底差在哪
import re

FILES = {
    "GOOD_s208-now": "/mnt/c/ios26/s208-now.bin",
    "BAD_now-0548":  "/mnt/c/ios26/now-054802.bin",
}

def load(p):
    return open(p, "rb").read().decode("utf-8", "replace")

def show_lines(d, tag, pred, lim=25):
    out = [l.strip() for l in d.splitlines() if pred(l)]
    print(f"\n--- [{tag}] {tag} : {len(out)} lines (show {min(lim,len(out))}) ---")
    for l in out[:lim]:
        print("  ", l[:210])
    if len(out) > lim:
        print("   ...")
        for l in out[-3:]:
            print("  ", l[:210])

for name, p in FILES.items():
    d = load(p)
    print("\n" + "#"*110)
    print("###", name, p.split("/")[-1], "size", len(d))
    # date prefixes
    dates = re.findall(r"\b(20\d{2}-\d{2}-\d{2})\b", d)
    from collections import Counter
    print("  dates:", Counter(dates).most_common(6))
    # last lines: is system still alive
    tail = [l.strip() for l in d.splitlines() if l.strip()][-25:]
    print("\n--- [tail] last 25 lines ---")
    for l in tail:
        print("  ", l[:210])

    show_lines(d, "activation/mobileactivation", lambda l: "activation" in l.lower() or "Unactivated" in l, 18)
    show_lines(d, "Setup Assistant", lambda l: "Setup" in l or "setup" in l and "Assistant" in l, 12)
    show_lines(d, "sb26 inject", lambda l: "sb26:" in l, 18)
    show_lines(d, "SpringBoard[33", lambda l: "SpringBoard[33" in l, 10)
    show_lines(d, "render pipelines / Metal", lambda l: "render pipeline" in l.lower() or "THE GPU STAYS" in l, 8)
    show_lines(d, "unlock/firstunlocked", lambda l: "unlock" in l.lower() or "FirstUnlocked" in l, 12)
