import re
paths=[
 '/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/Availability.h',
 '/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/os/availability.h',
]
for p in paths:
    print('==========',p)
    lines=open(p).read().split('\n')
    for i,l in enumerate(lines):
        if re.match(r'\s*#\s*define\s+(API_|__API_|NS_AVAILABLE|NS_DEPRECATED)', l):
            print('%4d: %s' % (i+1, l[:160]))
