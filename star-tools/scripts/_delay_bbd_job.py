import plistlib, sys

P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.backboardd.plist"
d = plistlib.load(open(P, "rb"))
print("before: RunAtLoad=%r StartInterval=%r KeepAlive=%r" % (d.get("RunAtLoad"), d.get("StartInterval"), d.get("KeepAlive")))

d["RunAtLoad"] = False          # do not start with the rest of the boot
d["StartInterval"] = 150        # first launch 150 s after the job is loaded

open(P, "wb").write(plistlib.dumps(d, fmt=plistlib.FMT_BINARY))
e = plistlib.load(open(P, "rb"))
print("after:  RunAtLoad=%r StartInterval=%r KeepAlive=%r" % (e.get("RunAtLoad"), e.get("StartInterval"), e.get("KeepAlive")))
print("keys:", sorted(e.keys()))
