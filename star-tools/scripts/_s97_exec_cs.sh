#!/bin/bash
cd /root/star26/star-native || exit 1
echo "===== A) kern_exec.c 9080-9200 ====="
sed -n '9080,9200p' bsd/kern/kern_exec.c
echo
echo "===== B) kern_exec.c 2260-2290 ====="
sed -n '2260,2290p' bsd/kern/kern_exec.c
echo
echo "===== C) entitlements EINVAL sites ====="
grep -rn "EINVAL" bsd/kern/ubc_subr.c | sed -n '1,40p'
echo
echo "===== D) csblob_get_entitlements ====="
grep -rn "csblob_get_entitlements\|cs_entitlements_blob_get\|CS_OPS_ENTITLEMENTS_BLOB" --include=*.c --include=*.h . 2>/dev/null | grep -v "\.bak" | head -20
echo
echo "===== E) cs_ops EINVAL path ====="
grep -n "csops\|cs_ops" bsd/kern/kern_cs.c | head -20
echo
echo "===== DONE ====="
