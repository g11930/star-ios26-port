import re, subprocess

def wsl(cmd):
    return subprocess.run(["wsl.exe","-d","Ubuntu-24.04","bash","-c",cmd],
                          capture_output=True, text=True).stdout

# star-native: tracked-modified + untracked, vs ac9718f
out = wsl("cd /root/star26/star-native && { git diff --name-only ac9718f; git ls-files --others --exclude-standard; } | sort -u")
star = set(x.strip() for x in out.splitlines() if x.strip())

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
dada = set(x.strip() for x in out.splitlines() if x.strip())

# high-value files that matter for launchd/xpc/service check-in
key = [
 "bsd/kern/kern_minimac.c","libkern/amfi/miniamfi.c","libkern/amfi/miniamfi_entitlements.cpp",
 "bsd/kern/kern_credential.c","bsd/kern/ubc_subr.c","osfmk/ipc/ipc_policy.c",
 "osfmk/ipc/ipc_kmsg.c","osfmk/ipc/mach_port.c","iokit/Kernel/GenericARMPE.cpp",
 "bsd/miscfs/apfs/apfs_vfsops.c","bsd/miscfs/apfs/apfs_vnops.c","bsd/miscfs/ramfs/ramfs.c",
]
print("star-native total (tracked-mod + untracked):", len(star))
for f in key:
    tag = []
    if f in dada: tag.append("DADA")
    if f in star: tag.append("OURS")
    if f in dada and f in star: tag.append("BOTH")
    print(f"  {f:55s} {'+'.join(tag) if tag else 'NEITHER'}")
