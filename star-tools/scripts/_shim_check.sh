#!/bin/bash
echo "=== search whole disk trees for the string ==="
grep -rn 'the gpu was not started' /root/star26 /root/g11930-ref 2>/dev/null | grep -v '\.bin\|\.img\|Binary' | head -8
echo
echo "=== annibalemetal sources ==="
ls /root/star26/hackios-xnu-userland/userland/src/ 2>/dev/null | grep -i 'metal\|sb' | head -10
echo
echo "=== who owns the 'annibalemetal[...]' prefix ==="
grep -rln 'annibalemetal\[' /root/star26 2>/dev/null | grep -v Binary | head -6
</bash>
