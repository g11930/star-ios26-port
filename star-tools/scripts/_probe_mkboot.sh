#!/bin/bash
S=/mnt/d/桌面/star26-deps/scripts
echo "== make-boot.py usage =="
grep -nE "argv|usage|sys.argv|add_argument" "$S/make-boot.py" 2>/dev/null | head -20
echo
echo "== head 45 =="
sed -n '1,45p' "$S/make-boot.py" 2>/dev/null
