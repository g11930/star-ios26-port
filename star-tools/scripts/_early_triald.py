import plistlib

# 1) triald: start with the boot, so RunningBoard's TRIClient does not block
P1 = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.triald.plist"
d = plistlib.load(open(P1, "rb"))
print("triald before: RunAtLoad=%r KeepAlive=%r" % (d.get("RunAtLoad"), d.get("KeepAlive")))
d["RunAtLoad"] = True
d["KeepAlive"] = True
open(P1, "wb").write(plistlib.dumps(d, fmt=plistlib.FMT_BINARY))
e = plistlib.load(open(P1, "rb"))
print("triald after:  RunAtLoad=%r KeepAlive=%r" % (e.get("RunAtLoad"), e.get("KeepAlive")))

# 2) backboardd: restore the stock job behaviour
P2 = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.backboardd.plist"
b = plistlib.load(open(P2, "rb"))
print("backboardd before: RunAtLoad=%r KeepAlive=%r StartInterval=%r" % (b.get("RunAtLoad"), b.get("KeepAlive"), b.get("StartInterval")))
b["RunAtLoad"] = True
b["KeepAlive"] = True
b.pop("StartInterval", None)
open(P2, "wb").write(plistlib.dumps(b, fmt=plistlib.FMT_BINARY))
f = plistlib.load(open(P2, "rb"))
print("backboardd after:  RunAtLoad=%r KeepAlive=%r StartInterval=%r" % (f.get("RunAtLoad"), f.get("KeepAlive"), f.get("StartInterval")))
