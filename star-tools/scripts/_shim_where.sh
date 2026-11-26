#!/bin/bash
grep -rn --include=*.m --include=*.c --include=*.cpp --include=*.h --include=*.mm -l 'render pipelines' /root 2>/dev/null | head -6
echo "=== libannibalemetal source ==="
grep -rln 'annibalemetal' /root --include=*.m --include=*.c 2>/dev/null | head -8
</>
