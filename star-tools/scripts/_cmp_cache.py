import sys, plistlib, json
sys.path.insert(0, "/root/star-build/tools/apfs")
import apfs

def load(root):
    v = apfs.Container(root).volumes()[0]
    ino = v.lookup("/xpc/launchd.plist")
    ino = ino[0] if isinstance(ino, tuple) else ino
    return plistlib.loads(v.inode(ino).contents())

old = load("/root/star26/s111/root11.apfs")   # s123
new = load("/root/star26/s111/root12.apfs")   # s124

print("top keys old:", sorted(k for k in old if k != "LaunchDaemons"))
print("top keys new:", sorted(k for k in new if k != "LaunchDaemons"))
print()
o, n = old["LaunchDaemons"], new["LaunchDaemons"]
print("job count old/new:", len(o), len(n))
only_old = set(o) - set(n)
only_new = set(n) - set(o)
print("only in old:", sorted(only_old)[:10])
print("only in new:", sorted(only_new)[:10])

changed = [k for k in set(o) & set(n) if o[k] != n[k]]
print("changed jobs:", sorted(changed))
for k in sorted(changed):
    a, b = o[k], n[k]
    diff = {f: (a.get(f), b.get(f)) for f in set(a) | set(b) if a.get(f) != b.get(f)}
    print("  ", k.split("/")[-1], {kk: (str(vv[0])[:60], str(vv[1])[:60]) for kk, vv in diff.items()})
