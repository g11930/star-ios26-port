import re
p = "/root/ref/dada/kernel/xnu-12377.121.6-dada.patch"
targets = {"osfmk/ipc/ipc_kmsg.c", "osfmk/ipc/ipc_policy.c", "osfmk/ipc/mach_port.c", "osfmk/kern/thread.c"}
with open(p, "r", errors="replace") as f:
    lines = f.readlines()
# find hunk ranges
ranges = []
cur = None
for i, l in enumerate(lines):
    if l.startswith("diff --git "):
        m = re.search(r" b/(.+?)$", l.rstrip())
        cur = m.group(1) if m else None
        if cur in targets:
            ranges.append([cur, i, i+1])
        else:
            cur = None
    elif cur in targets:
        ranges[-1][2] = i+1
for name, s, e in ranges:
    print("="*70)
    print(f"### {name}  (patch lines {s+1}-{e})")
    print("="*70)
    print("".join(lines[s:e]), end="")
