#!/bin/bash
for t in s150 s151 s152 s153 s154; do
	echo "--- $t"
	echo -n "compiler_library: "; grep -ac 'needs the compiler library' /tmp/$t.txt 2>/dev/null || echo 0
	grep -a 'compiler library' /tmp/$t.txt 2>/dev/null | head -2
	echo -n "failed_alloc: "; grep -ac 'Failed to allocate' /tmp/$t.txt 2>/dev/null || echo 0
	echo -n "swaps: "; grep -ac 'surface swap' /tmp/$t.txt 2>/dev/null || echo 0
done
