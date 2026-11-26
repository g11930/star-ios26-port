#!/bin/bash
for t in s150 s151 s152 s153 s154 s155; do
	echo -n "$t last-log: "
	grep -a '^2025-12-10' /tmp/$t.txt 2>/dev/null | tail -1 | cut -c1-30
	echo -n "   swaps: "; grep -ac 'surface swap' /tmp/$t.txt 2>/dev/null || echo 0
done
</