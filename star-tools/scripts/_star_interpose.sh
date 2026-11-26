#!/bin/bash
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
echo "=== star interpose/grep ==="
grep -n 'interpose\|MGCopyAnswer\|CFBundleCopyBundleLocalizations\|dyld_interpose' "$S" | head -20
echo "=== star includes ==="
grep -n '#include' "$S" | head -25
echo "=== star tail 40 ==="
tail -40 "$S"
