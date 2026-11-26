#!/bin/bash
U=/root/star26/hackios-xnu-userland/userland
grep -rln 'input26' $U/src 2>/dev/null | head -10
echo "=== log lines around dispatch ==="
F=$(grep -rln 'input26: standalone' $U/src 2>/dev/null | head -1)
echo "file: $F"
[ -n "$F" ] && grep -n 'say(' "$F" | head -20
</