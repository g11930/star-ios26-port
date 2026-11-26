import re, os, shutil
base='/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk/usr/include'
files=[base+'/Availability.h', base+'/os/availability.h']
probes=[
 r'__has_attribute\(availability\)',
 r'__has_feature\(attribute_availability_with_message\)',
 r'__has_feature\(attribute_availability_app_extension\)',
 r'__has_feature\(attribute_availability_tvos\)',
 r'__has_feature\(attribute_availability_watchos\)',
 r'__has_feature\(attribute_availability_swift\)',
 r'__has_feature\(attribute_availability\)',
]
for p in files:
    if not os.path.exists(p):
        print('MISSING', p); continue
    if os.path.islink(p):
        real=os.path.realpath(p)
        os.remove(p)
        shutil.copy2(real, p)
    s=open(p).read()
    total=0
    for pat in probes:
        s,n=re.subn(pat,'0',s); total+=n
    open(p,'w').write(s)
    print('%-70s patched %d probes' % (p, total))
