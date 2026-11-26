p='/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/System/Library/Frameworks/CoreFoundation.framework/Headers/CFAvailability.h'
s=open(p).read()
old='#if __has_include(<Availability.h>) && __has_include(<os/availability.h>) && __has_include(<AvailabilityMacros.h>)'
if old in s:
    s=s.replace(old, '#if 0 /* iconfill: force noop API_AVAILABLE for stock clang */', 1)
    open(p,'w').write(s)
    print('patched CFAvailability.h')
elif 'iconfill: force noop' in s:
    print('already patched')
else:
    print('PATTERN NOT FOUND'); raise SystemExit(2)
