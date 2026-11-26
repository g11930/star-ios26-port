import plistlib, json
P = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/com.apple.runningboardd.plist"
d = plistlib.load(open(P, "rb"))
print("MachServices:", json.dumps(d.get("MachServices"), indent=1))
