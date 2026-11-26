#!/bin/bash
L=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
NM=/usr/bin/llvm-nm
echo "=== extern symbols matching rwa_buffer ==="
"$NM" -gU "$L" 2>/dev/null | grep -i "rwa_buffer" | head -10
echo "=== any symbol at all? count ==="
"$NM" -gU "$L" 2>/dev/null | wc -l
echo "=== try exports trie via objdump ==="
/usr/bin/llvm-objdump --macho --exports-trie "$L" 2>/dev/null | grep -i "rwa_buffer" | head -10
