import plistlib
P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.triald.plist"
d = plistlib.load(open(P, "rb"))
d.pop("RunAtLoad", None)
d.pop("KeepAlive", None)
open(P, "wb").write(plistlib.dumps(d, fmt=plistlib.FMT_BINARY))
e = plistlib.load(open(P, "rb"))
print("triald keys:", sorted(e.keys()))
print("RunAtLoad=%r KeepAlive=%r EnablePressuredExit=%r" % (e.get("RunAtLoad"), e.get("KeepAlive"), e.get("EnablePressuredExit")))
