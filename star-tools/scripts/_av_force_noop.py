import os
# Force no-op availability macros at the very top of the two headers that define them.
# Back up originals first (dereference symlink -> real copy).
paths = [
  '/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/Availability.h',
  '/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/os/availability.h',
]
GUARD = '/* ICONFILL_NOOP_AVAIL */\n'
MACROS = '''#undef API_AVAILABLE
#undef API_UNAVAILABLE
#undef API_DEPRECATED
#undef API_DEPRECATED_WITH_REPLACEMENT
#undef API_AVAILABLE_BEGIN
#undef API_AVAILABLE_END
#undef API_UNAVAILABLE_BEGIN
#undef API_UNAVAILABLE_END
#define API_AVAILABLE(...)
#define API_UNAVAILABLE(...)
#define API_DEPRECATED(...)
#define API_DEPRECATED_WITH_REPLACEMENT(...)
#define API_AVAILABLE_BEGIN(...)
#define API_AVAILABLE_END
#define API_UNAVAILABLE_BEGIN(...)
#define API_UNAVAILABLE_END
'''
for p in paths:
    if not os.path.exists(p):
        print('MISSING', p); continue
    bak = p + '.iconfill-bak'
    if not os.path.exists(bak):
        import shutil
        shutil.copy2(p, bak)
    s = open(p).read()
    if 'ICONFILL_NOOP_AVAIL' in s:
        print('already', p); continue
    open(p, 'w').write(GUARD + MACROS + s)
    print('patched', p)
