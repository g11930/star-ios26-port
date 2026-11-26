#!/bin/bash
F=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c
echo "=== helper presence in star ==="
for s in sb26_ask sb26_utf8 sb26_uiimage_at sb26_fill_all_icons objc_getAssociatedObject dispatch_after NSEC_PER_SEC notify_register_dispatch CFSTR; do
  n=$(grep -c "$s" "$F")
  printf "%-30s %s\n" "$s" "$n"
done
echo
echo "=== includes (first 45 lines) ==="
sed -n '1,45p' "$F"
echo
echo "=== dispatch/notify usage ==="
grep -nE 'dispatch_after|dispatch_get_main_queue|NSEC_PER_SEC|notify_register' "$F" | head -12
echo
echo "=== constructor tail (last 22 lines of file) ==="
tail -22 "$F"
