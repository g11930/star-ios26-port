#!/bin/bash
AV=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include/Availability.h
echo "=== before ==="
ls -la "$AV"
if [ -L "$AV" ]; then
  echo "is symlink -> $(readlink "$AV")"
  cp --remove-destination "$(readlink -f "$AV")" "$AV"
  echo "detached to real file"
fi
python3 - "$AV" <<'PY'
import sys
p=sys.argv[1]
s=open(p).read()
if 'STOCK_CLANG_NOOP_AVAILABILITY' in s:
    print('already patched'); raise SystemExit
marker='#define API_AVAILABLE'
idx=s.find(marker)
if idx<0:
    print('NO API_AVAILABLE marker'); raise SystemExit(2)
override='''#ifndef STOCK_CLANG_NOOP_AVAILABILITY
#define STOCK_CLANG_NOOP_AVAILABILITY 1
#undef API_AVAILABLE
#undef API_UNAVAILABLE
#undef API_DEPRECATED
#undef API_DEPRECATED_WITH_REPLACEMENT
#define API_AVAILABLE(...)
#define API_UNAVAILABLE(...)
#define API_DEPRECATED(...)
#define API_DEPRECATED_WITH_REPLACEMENT(...)
#endif
'''
open(p,'w').write(s[:idx]+override+s[idx:])
print('patched', p)
PY
grep -n "STOCK_CLANG_NOOP_AVAILABILITY" "$AV" | head -3
