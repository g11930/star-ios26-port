#!/bin/bash
cd /root/star26/star-native
echo "--- console write helpers ---"
grep -rn 'star_console\|console_write\|pe_putc\|cnputc\|conslog_putc' bsd/dev/star/*.c bsd/dev/star/*.h osfmk/arm/*.c 2>/dev/null | head -12
echo "--- how display probe prints ---"
grep -rn 'printf(' bsd/dev/star/star_display_probe.c 2>/dev/null | head -3
</>
