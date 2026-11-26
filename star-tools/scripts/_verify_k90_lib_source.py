#!/usr/bin/env python3
"""Is the K90 v0.2.1 release dylib built from inject_sb26_v021.c? Check embedded markers."""
import hashlib
lib="/mnt/d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1/root/lib/libannibale-sb26.dylib"
src="/mnt/d/桌面/star26-deps/k90-ref/inject_sb26_v021.c"
d=open(lib,"rb").read(); s=open(src,"rb").read()
print("lib size=%d sha256=%s"%(len(d),hashlib.sha256(d).hexdigest()))
print("src size=%d sha256=%s"%(len(s),hashlib.sha256(s).hexdigest()))

# distinctive format strings from v0.2.1 source; if present in lib => lib built from this source
markers=[
 "waiting for CoverSheet _appearState==2",
 "build=23G90 activation_installed",
 "unlock %s:",
 "MGCopyAnswer",
 "offline interception installed",
 "CoverSheet",
 "appearState",
]
print("\n=== v0.2.1 source markers in compiled lib ===")
for m in markers:
    print("  %-42s src=%d lib=%d"%(m[:42], s.count(m.encode()), d.count(m.encode())))

# compare with v0.1.4 source markers (to see which version the release lib matches)
s14=open("/mnt/d/桌面/star26-deps/k90-ref/inject_sb26_v014.c","rb").read()
print("\n=== v0.1.4-only vs v0.2.1-only distinguishing markers ===")
# find strings present in one source but not the other, then check lib
import re
def strings(b):
    return set(x.decode("utf-8","ignore") for x in re.findall(rb"[ -~]{8,}",b))
ss21=strings(s); ss14=strings(s14)
only21=ss21-ss14; only14=ss14-ss21
print("strings only in v0.2.1 src: %d, only in v0.1.4 src: %d"%(len(only21),len(only14)))
libstr=strings(d)
# check a few substantive ones (skip pure code)
def filt(xs):
    out=[]
    for x in xs:
        if any(k in x.lower() for k in ["fprintf","sb26:","unlock","cover","appear","activation","rate","bundle","identifier","screen","display"]):
            out.append(x)
    return sorted(out)[:20]
print("  only-v0.2.1 substantive found in lib:")
for x in filt(only21):
    print("    %-70r inlib=%s"%(x[:70], x in libstr))
