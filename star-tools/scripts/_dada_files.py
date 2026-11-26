import re
p = "/root/ref/dada/kernel/xnu-12377.121.6-dada.patch"
kw = re.compile(r"ipc|mach_msg|mach_port|bootstrap|kern/thread|kern/task|kern/ast|ipc_kmsg|ipc_mqueue|ipc_space|sync", re.I)
with open(p, "r", errors="replace") as f:
    lines = f.readlines()
files = []
for i, l in enumerate(lines):
    if l.startswith("diff --git "):
        m = re.search(r" b/(.+?)$", l.rstrip())
        if m:
            files.append((i, m.group(1)))
print("total files in patch:", len(files))
print("=== IPC/MSG related ===")
for i, fp in files:
    if kw.search(fp):
        print(f"  L{i+1}: {fp}")
