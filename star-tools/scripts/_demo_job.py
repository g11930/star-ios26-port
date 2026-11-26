import plistlib, json, os

P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.annibale.demo.plist"
d = plistlib.load(open(P, "rb"))
print(json.dumps(d, indent=1, default=str))
print("---- launchctl:")
for p in ("/root/sys-root/usr/bin/launchctl", "/root/sys-root/bin/launchctl", "/root/sys-root/sbin/launchctl"):
    print(p, os.path.exists(p))
