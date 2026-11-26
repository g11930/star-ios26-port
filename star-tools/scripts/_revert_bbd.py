import plistlib
P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.backboardd.plist"
d = plistlib.load(open(P, "rb"))
d["ProgramArguments"] = ["/usr/libexec/backboardd"]
open(P, "wb").write(plistlib.dumps(d, fmt=plistlib.FMT_BINARY))
e = plistlib.load(open(P, "rb"))
print("backboardd ProgramArguments:", e["ProgramArguments"])
print("RunAtLoad=%r KeepAlive=%r" % (e.get("RunAtLoad"), e.get("KeepAlive")))
