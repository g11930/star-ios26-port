#!/bin/bash
echo "=== userland tree: ignition/preboot ==="
grep -rn -i "ignition\|preboot" /root/star26/hackios-xnu-userland --include='*.c' --include='*.h' --include='*.md' --include='*.py' --include='*.sh' 2>/dev/null | head -30
echo "=== k90 kernel: boot objects / ignition ==="
grep -rn -i "boot-objects\|bootobjects\|ignition" /root/star26/kbuild/xnu-12377.121.6/bsd --include='*.c' --include='*.h' 2>/dev/null | head -20
echo "=== star-native: boot objects ==="
grep -rn -i "boot-objects\|bootobjects" /root/star26/star-native/bsd --include='*.c' --include='*.h' 2>/dev/null | head -20
