#!/bin/bash
# Reproducible assembly of a buildable K90 xnu-12377.121.6 tree on Linux.
#
# Prerequisites (all already present in this workspace):
#   /root/xnu26-test/xnu-12377.121.6/.git  -- Apple xnu-12377.121.6 at ac9718fb
#   /root/star26/hackios-xnu-kernel/       -- K90 tree: xnu26/patches (78),
#                                             xnu/files (194), xnu26/files (2)
#
# Produces /root/star26/kbuild/xnu-12377.121.6, a detached git worktree, so the
# previously linked feasibility tree is never touched.
set -e
SRC=/root/xnu26-test/xnu-12377.121.6
DST=/root/star26/kbuild/xnu-12377.121.6
K=/root/star26/hackios-xnu-kernel
SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

[ "$(git -C "$SRC" rev-parse HEAD)" = "ac9718fb1af618d5ce8678d0dc6e8a58f252216f" ] || {
    echo "baseline mismatch: expected ac9718fb" >&2; exit 1; }

cd "$SRC"
git worktree remove --force "$DST" 2>/dev/null || true
rm -rf /root/star26/kbuild
mkdir -p /root/star26/kbuild
git worktree add --detach "$DST" HEAD >/dev/null

cd "$DST"
applied=0
while IFS= read -r f; do
    git apply --whitespace=nowarn "$K/xnu26/patches/$f" || {
        echo "patch failed: $f" >&2; exit 1; }
    applied=$((applied + 1))
done < "$K/xnu26/patches/series"
echo "applied $applied patches"

(cd "$K/xnu/files" && find . -type f -o -type l) | sed 's|^\./||' |
    while IFS= read -r f; do
        mkdir -p "$(dirname "$f")"
        cp -P -p "$K/xnu/files/$f" "$f"
    done
cp -R -P -p "$K/xnu26/files/." .
echo "copied K90 sources"

python3 "$SCRIPTS/apply-wsl-fixups.py" "$DST"
echo "ASSEMBLED $DST"
