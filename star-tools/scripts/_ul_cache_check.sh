#!/bin/bash
# how does OUR userland deliver the launchd cache?
U=/root/star26/hackios-xnu-userland
echo "===== 1. cache-related files in our userland ====="
find "$U" -maxdepth 3 -iname '*cache*' -o -maxdepth 3 -iname '*launchd*' 2>/dev/null | grep -v '\.git' | head -20
echo
echo "===== 2. mkcache.py header (first 40 lines) ====="
head -40 "$U/userland/mkcache.py" 2>/dev/null
echo
echo "===== 3. who runs mkcache / cache_loader in build scripts ====="
grep -rn 'mkcache\|cache_loader\|launchd.plist\|launchd_unsecure' "$U" --include='*.sh' --include='*.py' --include='Makefile*' 2>/dev/null | grep -v '\.git' | head -20
echo
echo "===== 4. launchd_cache_loader binary/source present? ====="
find "$U" -iname '*cache_loader*' 2>/dev/null | head -5
echo
echo "===== 5. s73 log: launchd domain / xpc context lines (sample) ====="
strings -n 6 /mnt/c/ios26/s73-log.bin | grep -E 'com\.apple\.xpc\.launchd\|' | grep -i -E 'domain|socket|launch|spawn|xpc|bootstrap|cache|error|fault' | head -30
