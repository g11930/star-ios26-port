import plistlib

P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.backboardd.plist"
d = plistlib.load(open(P, "rb"))
print("before:", d.get("ProgramArguments"))
d["ProgramArguments"] = ["/annibale/bin/delayexec", "150", "/usr/libexec/backboardd"]
open(P, "wb").write(plistlib.dumps(d, fmt=plistlib.FMT_BINARY))
e = plistlib.load(open(P, "rb"))
print("after: ", e.get("ProgramArguments"))
print("RunAtLoad=%r KeepAlive=%r" % (e.get("RunAtLoad"), e.get("KeepAlive")))
