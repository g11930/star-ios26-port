#!/bin/bash
L=/root/star26/s111/work/rootbuild/root/lib
ls -l $L/libOSMesa.8.dylib $L/libannibaleair.dylib 2>/dev/null
echo "=== disk cache support in mesa ==="
strings -a $L/libOSMesa.8.dylib 2>/dev/null | grep -c 'MESA_SHADER_CACHE'
strings -a $L/libOSMesa.8.dylib 2>/dev/null | grep 'MESA_SHADER_CACHE\|disk_cache' | head -6
echo "=== in libannibaleair ==="
strings -a $L/libannibaleair.dylib 2>/dev/null | grep -c 'MESA_SHADER_CACHE'
</>
