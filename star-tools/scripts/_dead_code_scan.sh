#!/bin/bash
# Report which added .c files are referenced by the build config, and which are dead.
set -u
TREE=/root/star26/star-native
cd "$TREE" || exit 1

echo "=== [1] added .c/.cpp files and whether the config references them ==="
git diff --name-status ac9718f HEAD | grep '^A' | cut -f2 \
  | grep -E '\.(c|cpp)$' | grep -vE '\.bak$|\.pre-' | sort | while read -r f; do
	base=$(basename "$f")
	# search all build config fragments for the path, excluding the file itself
	hits=$(grep -rl --include='files*' --include='Makefile*' --include='MakeInc*' \
	        --include='MASTER*' -F "$base" . 2>/dev/null | grep -v '^./BUILD' | grep -v "^./$f" | head -3 | tr '\n' ' ')
	if [ -z "$hits" ]; then
		echo "DEAD?   $f"
	else
		echo "ok      $f   <- $hits"
	fi
done

echo
echo "=== [2] #if 0 blocks per added file (dead code markers) ==="
git diff --name-status ac9718f HEAD | grep '^A' | cut -f2 \
  | grep -E '\.(c|cpp|inc|h)$' | grep -vE '\.bak$|\.pre-' | while read -r f; do
	n=$(grep -c '^#if 0' "$f" 2>/dev/null)
	[ "${n:-0}" != "0" ] && echo "$n  $f"
done | sort -rn | head -20
