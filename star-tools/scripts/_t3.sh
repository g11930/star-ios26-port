#!/bin/bash
R=/root/g11930-ref/xnu/files/bsd/dev/redwood_goodix.c
O=/root/star26/star-native/bsd/dev/star/annibale_goodix.c
diff -u $R $O > /tmp/touch.diff 2>&1
echo "diff lines: $(wc -l < /tmp/touch.diff)"
grep -c '^+' /tmp/touch.diff; grep -c '^-' /tmp/touch.diff
echo "=== hunks (headers) ==="
grep -n '^@@' /tmp/touch.diff | head -40