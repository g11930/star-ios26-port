#!/bin/bash
# s94 编译前状态自检：确认源码树 = s90 基线 + CS 补丁（无 s91 metal 无条件、无 s92 探针）
T=/root/star26/star-native
echo "=== 1) kern_cs.c CS patch present (want 3) ==="
grep -c "star_cs_keep_valid" "$T/bsd/kern/kern_cs.c"
echo "=== 2) mach_loader.c s92 probe absent (want 0) ==="
grep -c "star_cs_probe\|CS_INITPAGE_BAD" "$T/bsd/kern/mach_loader.c"
echo "=== 3) mach_loader unconditional clear present (want >=1) ==="
grep -c "result->csflags &= ~CS_VALID" "$T/bsd/kern/mach_loader.c"
echo "=== 4) Metal guard restored (want 1), unconditional setProperty absent ==="
echo -n "guard: "; grep -c "gAcceleratorTakesProperties && metal_native" "$T/iokit/Kernel/MiniFramebufferUserClient.inc"
echo -n "s91 selftest 3-attempt: "; grep -c "attempt < 3" "$T/iokit/Kernel/MiniFramebufferUserClient.inc"
echo "=== 5) modified files md5 ==="
md5sum "$T/bsd/kern/kern_cs.c" "$T/bsd/kern/mach_loader.c" "$T/iokit/Kernel/MiniFramebufferUserClient.inc"
echo "=== 6) backups present ==="
ls -la "$T/bsd/kern/kern_cs.c.s92.bak" "$T/bsd/kern/mach_loader.c.s94-pre-revert" "$T/iokit/Kernel/MiniFramebufferUserClient.inc.s93-pre-revert" "$T/iokit/Kernel/MiniFramebufferUserClient.inc.s90.bak"
