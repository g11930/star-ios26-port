import plistlib, os

paths = [
  ("s58 (current s-line)", "/root/star26/s58/work/root/xpc/launchd.plist"),
  ("p37 (iOS16 worked)", "/root/star26/p37/work/rootbuild/os/System/Library/xpc/launchd.plist"),
]
key = ["cfprefsd","configd","securityd","keybagd","lsd","logd","backboardd","SpringBoard",
       "usermanagerd","containermanagerd","runningboardd","wifid","distnoted","notifyd",
       "syslogd","powerd","mobilegestalt","chronod","installd","fseventsd","MTLCompiler",
       "cryptexd","splashboardd","useractivityd","locationd"]

for tag, p in paths:
    print("="*72)
    print(tag, os.path.getsize(p) if os.path.exists(p) else "MISSING")
    if not os.path.exists(p): continue
    d = plistlib.load(open(p,"rb"))
    ld = d.get("LaunchDaemons", {})
    names = list(ld.keys()) if isinstance(ld,dict) else []
    print("  LaunchDaemons count:", len(names))
    sysd = d.get("SystemLibraryTreeState", {})
    print("  SystemLibraryTreeState type:", type(sysd).__name__, "size:", len(sysd) if hasattr(sysd,'__len__') else "-")
    for k in key:
        hits = [n for n in names if k.lower() in n.lower()]
        mark = "OK" if hits else "!!"
        print(f"    {mark} {k:20s} {len(hits):2d}  {hits[:2]}")
