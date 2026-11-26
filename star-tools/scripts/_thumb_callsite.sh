#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
grep -rn 'rw_thumb(' $D/*.inc | head -8
grep -rn -B3 -A3 'rw_thumb_group_fits(' $D/*.inc | grep -v 'static bool' | head -12
</>
