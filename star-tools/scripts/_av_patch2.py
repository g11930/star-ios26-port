import re
p='/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include/Availability.h'
s=open(p).read()
if 'CLANG18_NOOP_APPLIED' in s:
    print('already patched'); raise SystemExit(0)
# Restore from stock first to avoid double-patch from earlier attempt
# (earlier _av_patch.sh failed to add marker, so s is unchanged except detached symlink)
s = '/* CLANG18_NOOP_APPLIED */\n' + s
# Force all availability feature probes to false -> no-op macro branches
subs = [
    (r'__has_attribute\(availability\)', '0'),
    (r'__has_feature\(attribute_availability_with_message\)', '0'),
    (r'__has_feature\(attribute_availability_app_extension\)', '0'),
    (r'__has_feature\(attribute_availability_tvos\)', '0'),
    (r'__has_feature\(attribute_availability_watchos\)', '0'),
    (r'__has_feature\(attribute_availability_swift\)', '0'),
    (r'__has_feature\(attribute_availability\)', '0'),
]
for pat, rep in subs:
    s, n = re.subn(pat, rep, s)
    print('%-52s %d' % (pat, n))
open(p,'w').write(s)
print('written', len(s), 'bytes')
