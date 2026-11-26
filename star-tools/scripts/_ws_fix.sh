#!/bin/bash
U=/root/star26/hackios-xnu-userland
echo "=== where window_server_fixes lives ==="
grep -rn 'window server hooks INCOMPLETE\|window_server_fixes' $U/userland/src $U/tools 2>/dev/null | head -8
echo
echo "=== the anchor check around it ==="
F=$(grep -rl 'window_server_fixes' $U/userland/src 2>/dev/null | head -1)
echo "file: $F"
grep -n 'window_server_fixes' -A60 "$F" 2>/dev/null | head -70
</bash>
</
</bash>
