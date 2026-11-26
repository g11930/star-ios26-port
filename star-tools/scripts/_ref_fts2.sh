#!/bin/bash
R=/root/g11930-ref/xnu/files/bsd/dev
ls $R | head -40
echo "=== sizes of touch candidates ==="
ls -l $R/redwood_input.c $R/redwood_focaltech*.c $R/redwood_fts*.c 2>/dev/null
echo "=== what does redwood_input.c create ==="
grep -n 'redwood-touch\|/dev/\|cdevsw\|make_dev' $R/redwood_input.c 2>/dev/null | head -12
</