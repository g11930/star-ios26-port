#!/bin/bash
OLD=/root/star-build/xnu-src/xnu-8796.121.2/bsd/dev/redwood_goodix.c   # 2393, WORKING STM
NEW=/root/star26/star-native/bsd/dev/star/annibale_goodix.c             # 1600, current iOS26
echo "=== line counts ==="; wc -l "$OLD" "$NEW"
echo
echo "=== header includes ==="
echo "--- OLD ---"; sed -n '20,40p' "$OLD"
echo "--- NEW ---"; sed -n '20,40p' "$NEW"
echo
echo "=== logging macros ==="
echo "--- OLD gdlog/printf defines ---"; grep -nE "define (gdlog|printf|say)|gdlog\(|printf\(" "$OLD" | head -8
echo "--- NEW ---"; grep -nE "define (gdlog|printf|say)|goodix_trace" "$NEW" | head -8
echo
echo "=== touch post API ==="
echo "--- OLD ---"; grep -nE "touch_post|redwood_touch|stm_touch" "$OLD" | tail -12
echo "--- NEW ---"; grep -nE "touch_post|annibale_touch|input" "$NEW" | tail -12
echo
echo "=== init function names ==="
grep -nE "goodix_init|redwood_goodix_init|annibale_goodix_init|_init\(void\)" "$OLD" | tail -5
grep -nE "goodix_init|redwood_goodix_init|annibale_goodix_init|_init\(void\)" "$NEW" | tail -5
