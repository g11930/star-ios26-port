#!/bin/bash
for t in /root/star26/kbuild/xnu-12377.121.6 /root/star26/star-native; do
	echo "=== $t"
	grep -rn "apfs-preboot-uuid" "$t/bsd" "$t/iokit" "$t/pexpert" --include='*.c' --include='*.cpp' --include='*.h' 2>/dev/null | head -10
	echo "--- IOGetApfsPrebootUUID"
	grep -rn "IOGetApfsPrebootUUID" "$t" --include='*.c' --include='*.cpp' --include='*.h' 2>/dev/null | head -10
done
echo "=== annibale dir (K90) ==="
ls /root/star26/kbuild/xnu-12377.121.6/bsd/dev/annibale/ 2>/dev/null
echo "=== star dir ==="
ls /root/star26/star-native/bsd/dev/star/ 2>/dev/null
