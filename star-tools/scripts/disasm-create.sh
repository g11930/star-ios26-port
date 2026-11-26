#!/bin/bash
L=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
/usr/bin/llvm-objdump --disassemble --start-address=0x55b4 --stop-address=0x584c "$L" 2>&1 | sed -n '1,200p'
