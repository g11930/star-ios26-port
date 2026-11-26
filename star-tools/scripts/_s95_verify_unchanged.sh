#!/bin/bash
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
echo "=== source md5 (three should be identical: current + 2 backups) ==="
md5sum "$S" "$S.s95-pre-xpc.bak" "$S.s95-pre-insert.bak" 2>&1
echo "=== shim present in source? (want 0 = not inserted) ==="
grep -c "sb26_hook_xpc_sync" "$S"
echo "=== source line count ==="
wc -l "$S"
