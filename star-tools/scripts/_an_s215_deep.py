#!/usr/bin/env python3
import sys, re
d = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
lines = d.splitlines()

# real panic only
realpanic = [l for l in lines if re.search(r"^\s*panic\(cpu|KERNEL FAULT|Debugger called|SoCReconfigured|the faulting|panic string", l, re.I)]
print("REAL PANIC lines=%d" % len(realpanic))
for l in realpanic[:5]: print("  >", l[:200])

# SpringBoard activity sample (first/middle/last)
sb = [l for l in lines if re.search(r"SpringBoard\[\d+\]", l)]
print("\nSpringBoard total=%d" % len(sb))
for tag, sub in [("EARLY", sb[:5]), ("MID", sb[len(sb)//2:len(sb)//2+5]), ("LATE", sb[-8:])]:
    print(" --- %s ---" % tag)
    for l in sub: print("  ", l[:210])

# what is SpringBoard doing? categorize
cats = {}
for l in sb:
    m = re.search(r"SpringBoard\[\d+\]:\s*(\w+)", l)
    key = m.group(1) if m else "?"
    cats[key] = cats.get(key, 0) + 1
print("\nSpringBoard message categories (top 25):")
for k, v in sorted(cats.items(), key=lambda x: -x[1])[:25]:
    print("  %-35s %d" % (k, v))

# scene / poster / icon / snapshot / home screen markers
print("\n=== desktop UI markers ===")
for label, pat in [
    ("scene", r"scene|Scene"),
    ("poster", r"poster|Poster"),
    ("snapshot", r"snapshot|Snapshot"),
    ("icon", r"icon|Icon"),
    ("home screen", r"home.?screen|Home.?Screen|SBHomeScreen"),
    ("wallpaper", r"wallpaper|Wallpaper"),
    ("unlock", r"unlock|Unlock"),
    ("activation", r"activation|Activation|activated"),
]:
    print("  %-14s %d" % (label, sum(1 for l in lines if re.search(pat, l))))
