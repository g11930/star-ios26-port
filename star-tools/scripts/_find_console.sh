#!/bin/bash
cd /root/star26/star-native
echo "--- STARX EAI_NAMEI emitter ---"
grep -rn 'STARX EAI' --include=*.c --include=*.cpp --include=*.h . 2>/dev/null | head -4
echo "--- functions named *_log/*_print in star dir ---"
grep -rn 'void\s+\w*log\w*(' --include=*.c --include=*.cpp bsd osfmk 2>/dev/null | grep -i 'star\|console\|boot' | head -8
echo "--- xnuloader log hook? ---"
grep -rn 'oem log\|log_ring\|klog' /root/star26/star-native/bsd/dev/star/*.c 2>/dev/null | head -5
</>
