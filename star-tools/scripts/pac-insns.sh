#!/bin/bash
F=/root/star26/p23/libannibalemetal.dylib
OD=/root/star26/kbuild/xnu-12377.121.6/tools/../BUILD  # unused, keep simple
DIS=$(ls /root/theos/toolchain/linux/iphone/bin/otool)
echo "=== count of PAC instructions in the new build ==="
/root/theos/toolchain/linux/iphone/bin/otool -tv "$F" 2>/dev/null | awk '{print $2}' | sort | uniq -c | sort -rn | grep -iE "pac|aut|braa|blraa|retaa|retab|xpaci|xpacd|pacib|autib" | head -20
echo "=== total instruction lines ==="
/root/theos/toolchain/linux/iphone/bin/otool -tv "$F" 2>/dev/null | wc -l
