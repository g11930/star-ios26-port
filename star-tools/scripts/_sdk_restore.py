import os, shutil
# Restore theos SDK originals from backups created during this session
restores = [
 '/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/Availability.h',
 '/root/theos/sdks/iPhoneOS16.5.sdk/usr/include/os/availability.h',
 '/root/theos/sdks/iPhoneOS16.5.sdk/System/Library/Frameworks/CoreFoundation.framework/Headers/CFAvailability.h',
]
for p in restores:
    bak=p+'.iconfill-bak'
    if os.path.exists(bak):
        shutil.copy2(bak,p)
        print('restored',p)
    elif 'iconfill' in open(p).read():
        print('NO BACKUP but modified:',p)
    else:
        print('clean',p)
# compat header (xnu-clang)
c='/root/star26/hackios-xnu-kernel/xnu-deps/hostinc/xnu_clang_compat.h'
cb=c+'.pre-iconfill.bak'
if os.path.exists(cb):
    shutil.copy2(cb,c); print('restored compat')
# inject source: keep the ported version (that's the actual fix), do not restore
print('inject_sb26.c kept (contains icon-fill fix)')
