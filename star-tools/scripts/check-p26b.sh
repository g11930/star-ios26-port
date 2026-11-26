#!/bin/bash
L=/root/star26/p26/libannibaleair.dylib
D=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib.v013
echo "=== which tools ==="
for t in llvm-nm nm llvm-objdump objdump; do printf "%-14s %s\n" "$t" "$(command -v $t || echo missing)"; done
echo
echo "=== try each lister on the new lib ==="
if command -v llvm-nm >/dev/null; then
	echo "--- llvm-nm default ---"
	llvm-nm "$L" 2>&1 | head -3
	echo "--- llvm-nm -gU ---"
	llvm-nm -gU "$L" 2>&1 | head -3
	echo "--- rwa count (default) ---"
	llvm-nm --defined-only "$L" 2>/dev/null | awk '{print $NF}' | grep -c '^_rwa_'
fi
echo
echo "=== strings-based check of the contract names ==="
strings "$L" | grep -c '^rwa_'
strings "$L" | grep '^rwa_' | head -8
echo
echo "=== distro library, same check ==="
strings "$D" | grep -c '^rwa_'
