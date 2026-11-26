import plistlib, json

G = "/root/star26/s111/work/rootbuild/root/LaunchDaemons/"
for f in ("com.apple.keybagd.plist", "com.apple.mobile.usermanagerd.plist"):
    try:
        d = plistlib.load(open(G + f, "rb"))
    except FileNotFoundError:
        print(f, "MISSING")
        continue
    print("=== " + f)
    print(json.dumps({k: (v if not isinstance(v, (dict, list)) else "<%s>" % type(v).__name__) for k, v in d.items()}, ensure_ascii=False, default=str))
    print()
