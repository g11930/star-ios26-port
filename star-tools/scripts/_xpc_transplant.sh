#!/bin/bash
OUT=/mnt/c/ios26/xpc_transplant.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c

e "=== 1) K90 XPC shim line range ==="
A=$(grep -n 'sb26_xpc_cache\[SB26_XPC_CACHE_MAX\]' "$K" | head -1 | cut -d: -f1)
Z=$(grep -n 'sb26_install_xpc\|install_xpc\|hook_xpc_sync' "$K" | tail -5 >> "$OUT" 2>&1; grep -n '^sb26_install_xpc\|xpc_shim\|install_xpc_hooks' "$K" | head -1 | cut -d: -f1)
e "cache decl at line $A"
e "--- markers with line numbers ---"
grep -n 'sb26_xpc_cache\[\|sb26_dead\[\|sb26_hook_xpc_sync\|sb26_install_xpc\|interpose\|DYLD_INTERPOSE\|rebind_symbols\|fishhook' "$K" >> "$OUT"

e ""
e "=== 2) how is the XPC hook installed (dyld interpose?) ==="
grep -n -B5 -A20 'send_message_with_reply_sync' "$K" | tail -80 >> "$OUT"

e ""
e "=== 3) star inject_sb26.c: does it have the constructor + build deps for xpc? ==="
grep -n 'constructor\|install_sb26\|_dyld_register\|#include' "$S" | head -30 >> "$OUT"
e "--- star build.sh: frameworks for sb26 dylib ---"
grep -n 'libannibale-sb26\|inject_sb26.c' /root/star26/hackios-xnu-userland/userland/build.sh | head -10 >> "$OUT"
e "--- K90 build.sh: frameworks ---"
grep -n 'inject_sb26.c\|libredwood-sb26' /root/star26/warsaw-ref/userland/build.sh | head -10 >> "$OUT"

e ""
e "=== 4) interpose mechanism availability: xpc headers in SDK? ==="
find /root/star-build/xnu-deps/sdk -path '*xpc/xpc.h' 2>/dev/null | head -3 >> "$OUT"
e "--- star binary links libxpc? check dylib ---"
find /root/star26/hackios-xnu-userland -name 'libannibale-sb26.dylib' -exec ls -la {} \; 2>/dev/null >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
