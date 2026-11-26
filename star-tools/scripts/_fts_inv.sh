#!/bin/bash
R=/root/g11930-ref
grep -rln 'focaltech\|focal_ts\|FT8719\|fts' $R/xnu/files/bsd/dev 2>/dev/null | head -10
echo "=== files with fts in name ==="
find $R -iname '*fts*' -o -iname '*focal*' 2>/dev/null | head -10
echo "=== goodix size/head ==="
ls -l $R/xnu/files/bsd/dev/redwood_goodix.c 2>/dev/null
grep -n 'goodix_init\|spi\|QUP\|SE11\|annibale_touch_post\|redwood_touch_post' $R/xnu/files/bsd/dev/redwood_goodix.c 2>/dev/null | head -12
</