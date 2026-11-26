import plistlib, json

G = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/"
for f in ("com.apple.mobile.usermanagerd.plist", "com.apple.triald.plist", "com.apple.backboardd.plist", "com.apple.runningboardd.plist"):
    d = plistlib.load(open(G + f, "rb"))
    print("=== " + f)
    print(json.dumps({k: (v if not isinstance(v, dict) else "<dict>") for k, v in d.items()}, ensure_ascii=False, default=str)[:900])
    print()
