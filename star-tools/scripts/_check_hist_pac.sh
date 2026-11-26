#!/bin/bash
D=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib.s213-pre
echo "=== 历史 dylib PAC 指令统计 (确认是 clang-11 风格) ==="
llvm-objdump -d --macho "$D" 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci|retaa'
echo "=== 样例几种 PAC 指令 ==="
llvm-objdump -d --macho "$D" 2>/dev/null | grep -iE 'pacibsp|blraaz|xpaci|autiasp' | head -5
echo "=== header cpusubtype ==="
python3 - "$D" <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x' % (cpu&0xffffffff,sub&0xffffffff))
PY
