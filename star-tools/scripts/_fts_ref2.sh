#!/bin/bash
R=/root/g11930-ref
grep -rln 'fts\|FTS\|k3s\|focaltech' $R/xnu/files 2>/dev/null | head -10
echo "=== who includes focaltech_fw.h ==="
grep -rn 'focaltech_fw' $R 2>/dev/null | head -5
echo "=== ref git log for touch files ==="
cd $R && git log --oneline --all -- '*fts*' '*touch*' '*input*' 2>/dev/null | head -10
git log --oneline -8 2>/dev/null
</