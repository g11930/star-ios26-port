#!/bin/bash
M=/root/star26/hackios-xnu-kernel/tools/mesa
ls $M 2>/dev/null | head
echo "=== get_param asks ==="
grep -rn 'get_param' $M --include=*.c --include=*.h 2>/dev/null | head -20
echo "=== MSM_PARAM defines ==="
grep -rn 'MSM_PARAM_' $M --include=*.h --include=*.c 2>/dev/null | head -25
</>
