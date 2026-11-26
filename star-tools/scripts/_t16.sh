#!/bin/bash
R=/root/g11930-ref
echo "=== repo head ==="
git -C $R log --oneline -8 2>/dev/null
echo "=== remote ==="
git -C $R remote -v 2>/dev/null
echo "=== files mentioning fts/STM/3639 ==="
grep -rln '3639\|st_fts\|STM\|fts_k2' $R --include=*.c --include=*.h --include=*.md 2>/dev/null | head -10