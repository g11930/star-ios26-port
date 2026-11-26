#!/bin/bash
D=/root/star26/hackios-xnu-kernel/tools/userland-driver
echo "=== setenv / env in driver ==="
grep -rn 'setenv\|MESA_\|getenv' $D/*.m $D/*.inc $D/*.h 2>/dev/null | head -20
echo "=== where mesa is loaded/initialised ==="
grep -rn 'OSMesa\|libOSMesa\|dlopen' $D/*.m $D/*.inc 2>/dev/null | head -10
</>
