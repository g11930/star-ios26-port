#!/bin/bash
OUT=/mnt/c/ios26/xpc_compare.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c

e "=== XPC sync hook markers: K90 vs star ==="
for pat in "sb26_hook_xpc_sync" "xpc_connection_send_message_with_reply_sync" "sb26_xpc_cache" "sb26_dead" "XPC_TYPE_ERROR" "SB26_XPC_CACHE_MAX" "sb26_xpc_cache_any" "root object is not an XPC dictionary" "send_message_with_reply"; do
  a=$(grep -c "$pat" "$K" 2>/dev/null)
  b=$(grep -c "$pat" "$S" 2>/dev/null)
  e "  %-46s K90=%-3s star=%s" "$pat" "$a" "$b"
done

e ""
e "=== star: any xpc hook at all? ==="
grep -n -i "xpc\|XPC" "$S" | head -40 >> "$OUT"

e ""
e "=== K90 XPC shim comments (700-800) ==="
sed -n '700,800p' "$K" >> "$OUT"

e ""
e "=== K90: where is the hook installed? (grep install of xpc) ==="
grep -n -B3 -A8 "hook_xpc_sync\|send_message_with_reply_sync" "$K" | tail -60 >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
