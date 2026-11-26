#!/bin/bash
echo "=== who prints 'say %d trace:' ==="
grep -rn 'trace: %s\|trace:' /root/star26/hackios-xnu-userland /root/star26/hackios-xnu-kernel/tools 2>/dev/null | grep -v Binary | grep -i 'say\|rw_print\|printf' | head -12
echo
echo "=== ann_say / say( definitions ==="
grep -rn 'ann_say\b' /root/star26/hackios-xnu-kernel/tools/userland-driver/*.m /root/star26/hackios-xnu-kernel/tools/userland-driver/*.inc 2>/dev/null | head -6
echo
echo "=== the sbmetal experiment library source ==="
grep -rln 'sbmetal' /root/star26/hackios-xnu-userland/userland/src 2>/dev/null | head -6
</bash>
