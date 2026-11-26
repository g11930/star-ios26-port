#!/bin/bash
I=/root/star26/hackios-xnu-userland/userland/src/inject/inject.c
grep -n 'readdir\|scandir\|experiment\|sbmetal\|_annibale_' $I | head -20
echo "=== files in inject src ==="
ls /root/star26/hackios-xnu-userland/userland/src/inject/
echo "=== grep experiment across userland src ==="
grep -rn 'sbmetal-experiment' /root/star26/hackios-xnu-userland/userland/ 2>/dev/null | grep -v '\.dylib' | head -10
</