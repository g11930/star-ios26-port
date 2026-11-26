#!/bin/bash
for f in /root/star-build/xnu-src/xnu-8796.121.2/bsd/dev/redwood_goodix.c /root/star-build/xnu/files/bsd/dev/redwood_goodix.c; do
  echo "==================== $f ($(wc -l < "$f" 2>/dev/null) lines)"
  grep -nE "TOUCH_STM|TOUCH_FOCALTECH|TOUCH_GOODIX|stm_|senseOn|0xA0|0x87|0xA7|chip id 0x|stm: |enum touch_chip|touch_chip_detect|touch_chip =|stm_poll|se_sites|0xa8c000|bit.*25|1u << 25" "$f" 2>/dev/null | head -45
  echo
done
