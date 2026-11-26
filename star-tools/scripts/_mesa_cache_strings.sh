#!/bin/bash
L=/root/star26/s111/work/rootbuild/root/lib/libannibaleair.dylib
strings -a $L | grep -i -E 'shader.?cache|cache_dir|disk_cache|glsl.?cache' | head -12
echo "=== cache substrings (any) ==="
strings -a $L | grep -i 'cache' | head -20
</>
