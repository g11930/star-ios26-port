import plistlib, os

paths = [
  "/root/star26/s58/work/root/xpc/launchd.plist",
  "/root/star26/s51/work/root/xpc/launchd.plist",  # earlier s-line
  "/root/star26/p37/work/rootbuild/os/System/Library/xpc/launchd.plist",  # P-series (iOS16, worked)
]
key = ["cfprefsd","configd","securityd","keybagd","lsd","logd","backboardd","SpringBoard",
       "usermanagerd","containermanagerd","runningboardd","wifid","distnoted","notifyd",
       "syslogd","powerd","mobilegestalt","chronod","installd","fseventsd","MTLCompiler"]

for p in paths:
    print("="*72)
    print(p, "exists:", os.path.exists(p), "size:", os.path.getsize(p) if os.path.exists(p) else "-")
    if not os.path.exists(p): continue
    try:
        d = plistlib.load(open(p,"rb"))
    except Exception as e:
        print("  parse error:", e); continue
    print("  top keys:", list(d.keys())[:6] if isinstance(d,dict) else type(d))
    # find job names
    jobs = None
    if isinstance(d, dict):
        for k in ("jobs","Services","jobsByName"):
            if k in d: jobs = d[k]; break
        if jobs is None: jobs = d
    if isinstance(jobs, dict):
        names = list(jobs.keys())
        print("  total jobs:", len(names))
        for k in key:
            hits = [n for n in names if k.lower() in n.lower()]
            print(f"    {k:20s} {len(hits):2d}  {hits[:3]}")
    elif isinstance(jobs, list):
        print("  total entries:", len(jobs))
        print("  sample:", jobs[:2])
