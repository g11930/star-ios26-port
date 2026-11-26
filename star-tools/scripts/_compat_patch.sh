#!/bin/bash
C=/root/star26/hackios-xnu-kernel/xnu-deps/hostinc/xnu_clang_compat.h
cp -n "$C" "$C.pre-iconfill.bak"
python3 - "$C" <<'PY'
import sys
p=sys.argv[1]
s=open(p).read()
if 'API_AVAILABLE(...)' in s:
    print('already patched'); raise SystemExit
add='''
/* stock clang lacks Apple's API_AVAILABILITY annotation macros; define them
 * as no-ops so Apple SDK headers with API_AVAILABLE(...) parse. */
#ifndef API_AVAILABLE
#define API_AVAILABLE(...)
#endif
#ifndef API_UNAVAILABLE
#define API_UNAVAILABLE(...)
#endif
#ifndef API_DEPRECATED
#define API_DEPRECATED(...)
#endif
#ifndef API_DEPRECATED_WITH_REPLACEMENT
#define API_DEPRECATED_WITH_REPLACEMENT(...)
#endif
#ifndef API_UNAVAILABLE_BEGIN
#define API_UNAVAILABLE_BEGIN(...)
#endif
#ifndef API_AVAILABLE_BEGIN
#define API_AVAILABLE_BEGIN(...)
#endif
#ifndef API_UNAVAILABLE_END
#define API_UNAVAILABLE_END
#endif
#ifndef API_DEPRECATED_BEGIN
#define API_DEPRECATED_BEGIN(...)
#endif
#ifndef API_DEPRECATED_END
#define API_DEPRECATED_END
#endif
#ifndef NS_AVAILABLE
#define NS_AVAILABLE(...)
#endif
#ifndef NS_AVAILABLE_IOS
#define NS_AVAILABLE_IOS(...)
#endif
#ifndef NS_DEPRECATED_IOS
#define NS_DEPRECATED_IOS(...)
#endif
'''
s = s.replace('#endif\n', add+'#endif\n', 1) if s.count('#endif')==1 else s + add
open(p,'w').write(s)
print('patched', p, len(s))
PY
tail -20 "$C"
