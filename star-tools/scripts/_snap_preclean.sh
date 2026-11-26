#!/bin/bash
# Take a pre-clean git snapshot of the star-native worktree WITHOUT BUILD/.
set -u
TREE=/root/star26/star-native
cd "$TREE" || exit 1

echo "=== [1] current HEAD ==="
git log --oneline -1

echo "=== [2] exclude file location ==="
EX=$(git rev-parse --git-path info/exclude)
echo "EX=$EX"
mkdir -p "$(dirname "$EX")"
if ! grep -q '^BUILD/' "$EX" 2>/dev/null; then
	echo 'BUILD/' >> "$EX"
fi
echo "--- exclude rules ---"
grep -v '^#' "$EX" | grep -v '^$'

echo "=== [3] stage everything except BUILD ==="
git add -A
echo "staged files total: $(git diff --cached --name-only | wc -l)"
echo "staged BUILD files: $(git diff --cached --name-only | grep -c '^BUILD/')"

echo "=== [4] commit ==="
git commit -q -m 'snapshot: pre-clean state (s201 PAC patch, debug leftovers included)'
git log --oneline -2
echo "=== [5] working tree after commit ==="
git status --porcelain | wc -l
