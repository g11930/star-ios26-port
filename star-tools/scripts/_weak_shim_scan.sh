#!/bin/bash
# For every weak shim in StarDisplayCompat.cpp, report whether a strong definition exists elsewhere.
set -u
TREE=/root/star26/star-native
cd "$TREE" || exit 1

F=iokit/Kernel/StarDisplayCompat.cpp
echo "=== weak shims in $F ==="
# extract the identifier that follows the weak attribute and precedes '('
grep -oE 'weak[^;{]*\b([a-z_][a-z0-9_]*)\s*\(' "$F" \
  | grep -oE '[a-z_][a-z0-9_]*\s*\($' | tr -d '( ' | sort -u > /tmp/weak_syms.txt
wc -l < /tmp/weak_syms.txt

echo
echo "symbol                      strong definition?"
echo "------------------------------------------------------------"
while read -r s; do
	[ -z "$s" ] && continue
	# find definitions: 'ret_type name(' at line start, excluding the weak file
	hits=$(grep -rn --include=*.c --include=*.cpp --include=*.inc -E "^[A-Za-z_][A-Za-z0-9_ \*]*[ \*]$s\(" . 2>/dev/null \
	        | grep -v '^./BUILD' | grep -v "^./$F" | head -3)
	if [ -z "$hits" ]; then
		echo "$(printf '%-28s' "$s") none (shim is the only definition)"
	else
		echo "$(printf '%-28s' "$s") YES"
		echo "$hits" | sed 's/^/    /'
	fi
done < /tmp/weak_syms.txt
