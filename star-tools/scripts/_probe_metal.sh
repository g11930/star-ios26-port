#!/bin/bash
echo "== who parses boot-arg metal =="
grep -rn 'PE_parse_boot_argn("metal"\|parse_boot_argn("metal"' /root/star26/kbuild/xnu-12377.121.6/ /root/star26/star-native/ 2>/dev/null | head -10
echo "== docs/metal.md mentions of metal=1 =="
grep -rn 'metal=1' /root/star26/hackios-xnu-kernel/docs/metal.md 2>/dev/null | head -12
echo "== userland reading metal boot-arg =="
grep -rn '"kern.bootargs"\|kern.bootargs' /root/star26/hackios-xnu-userland/userland/src/gfx/*.m /root/star26/hackios-xnu-userland/userland/src/inject/*.c 2>/dev/null | head -12
