import plistlib

P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.backboardd.plist"
d = plistlib.load(open(P, "rb"))
print("before: RunAtLoad=%r KeepAlive=%r StartInterval=%r" % (d.get("RunAtLoad"), d.get("KeepAlive"), d.get("StartInterval")))

d["RunAtLoad"] = False
d["KeepAlive"] = {"SuccessfulExit": False}   # no forced launch at load, but restart if it dies
d["StartInterval"] = 120                     # safety net: guaranteed first launch at T+120

open(P, "wb").write(plistlib.dumps(d, fmt=plistlib.FMT_BINARY))
e = plistlib.load(open(P, "rb"))
print("after:  RunAtLoad=%r KeepAlive=%r StartInterval=%r" % (e.get("RunAtLoad"), e.get("KeepAlive"), e.get("StartInterval")))
