import re, subprocess

def wsl(c):
    return subprocess.run(["wsl.exe","-d","Ubuntu-24.04","bash","-c",c],
                          capture_output=True, text=True).stdout

# files both modified, high relevance to process bootstrap / IPC / exceptions
key = [
 "bsd/kern/bsd_init.c","bsd/kern/kern_exec.c","bsd/kern/kern_exit.c",
 "bsd/kern/kern_sig.c","bsd/kern/kern_priv.c",
 "osfmk/kern/exception.c","osfmk/arm64/sleh.c","osfmk/kern/startup.c",
 "osfmk/kern/thread.c","osfmk/ipc/mach_port.c",
 "iokit/Kernel/IOUserClient.cpp","iokit/Kernel/IOService.cpp",
]
# our diff hunks per file (added lines only, normalized)
for f in key:
    d = wsl(f"cd /root/star26/star-native && git diff ac9718f -- {f} | grep '^+' | grep -v '^+++' | sed 's/^+//' | sed 's/^[[:space:]]*//' | head -40")
    ours = [x.strip() for x in d.splitlines() if x.strip() and not x.strip().startswith('*') and not x.strip().startswith('/*')]
    print("="*70)
    print("###", f, "— ours added key lines:", len(ours))
    for x in ours[:18]:
        print("  ", x[:110])
