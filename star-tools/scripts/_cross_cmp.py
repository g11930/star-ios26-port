import re, subprocess, os

def wsl(cmd):
    r = subprocess.run(["wsl.exe","-d","Ubuntu-24.04","bash","-c",cmd],
                       capture_output=True, text=True)
    return r.stdout

# 1. dada.patch 全部文件 — read patch via wsl-side python
py = r'''
import re
p="/root/ref/dada/kernel/xnu-12377.121.6-dada.patch"
for l in open(p,errors="replace"):
    if l.startswith("diff --git "):
        m=re.search(r" b/(.+?)$",l.rstrip())
        if m: print(m.group(1))
'''
out = subprocess.run(["wsl.exe","-d","Ubuntu-24.04","python3","-c",py],
                     capture_output=True, text=True).stdout
dada_files = set(x.strip() for x in out.splitlines() if x.strip())

# 2. star-native modified files vs ac9718f
out = wsl("cd /root/star26/star-native && git diff --name-only ac9718f")
star_files = set(x.strip() for x in out.splitlines() if x.strip())

# 3. kbuild (pristine-ish reference) modified files
out = wsl("cd /root/star26/kbuild/xnu-12377.121.6 && git diff --name-only ac9718f")
kb_files = set(x.strip() for x in out.splitlines() if x.strip())

print("dada patch files:", len(dada_files))
print("star-native modified:", len(star_files))
print("kbuild modified:", len(kb_files))

print("\n=== dada files NOT touched by star-native (potential missing fixes) ===")
for f in sorted(dada_files - star_files):
    print(" ", f)

print("\n=== files BOTH modified (compare needed) ===")
for f in sorted(dada_files & star_files):
    print(" ", f)

print("\n=== star-native modified but NOT in dada (star-specific) ===")
for f in sorted(star_files - dada_files):
    print(" ", f)
