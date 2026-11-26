#!/bin/bash
cd /root/star26/star-native
echo "=== exec inject/env hooks ==="
grep -rn 'exec_inject\|kern.exec\|inject_conf\|ENV_' bsd/kern/kern_exec.c bsd/dev/star/star_switch_root.c 2>/dev/null | head -14
echo "=== where inject list is applied ==="
grep -rn 'exec_inject' --include=*.c bsd osfmk | head -8
</>
