#!/bin/bash
# compare ref2 repos against the local /root/ref copies and our tree
echo "===== 1. dada kernel patch: local vs ref2 ====="
diff -q /root/ref/dada/kernel/xnu-12377.121.6-dada.patch \
        /root/ref2/hakios-arm64e-dada/kernel/xnu-12377.121.6-dada.patch 2>&1
diff /root/ref/dada/kernel/xnu-12377.121.6-dada.patch \
     /root/ref2/hakios-arm64e-dada/kernel/xnu-12377.121.6-dada.patch 2>/dev/null | head -5
echo "(empty above = identical)"
echo
echo "===== 2. warsaw patch list: local vs ref2 ====="
echo "---- local /root/ref/warsaw/xnu/patches (count):"
ls /root/ref/warsaw/xnu/patches/ 2>/dev/null | wc -l
echo "---- ref2 warsaw patches (count):"
ls /root/ref2/warsaw-xnu-kernel-RedmiK90Ultra/patches/ 2>/dev/null | wc -l
echo "---- ref2 warsaw patches newer than V37 era (names):"
ls /root/ref2/warsaw-xnu-kernel-RedmiK90Ultra/patches/ | tail -25
echo
echo "===== 3. warsaw docs dir (ref2) ====="
ls /root/ref2/warsaw-xnu-kernel-RedmiK90Ultra/docs/ | head -40
echo
echo "===== 4. annibale docs dirs ====="
ls /root/ref2/hackios-redmi-k90-annibale/docs/ 2>/dev/null | head -20
echo "---- progress:"
ls /root/ref2/hackios-redmi-k90-annibale/docs/progress/ 2>/dev/null | head -30
echo "---- backlog:"
ls /root/ref2/hackios-redmi-k90-annibale/docs/backlog/ 2>/dev/null | head -15
echo
echo "===== 5. ipc/turnstile/mach_msg-related patches in ref2 warsaw ====="
grep -l -i 'turnstile\|ipc_mqueue\|mach_msg\|ip_mq' /root/ref2/warsaw-xnu-kernel-RedmiK90Ultra/patches/* 2>/dev/null | head -10
echo
echo "===== 6. annibale kernel tree top ====="
ls /root/ref2/hackios-redmi-k90-annibale/hackios-xnu-kernel/ | head -20
