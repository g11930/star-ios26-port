import re, os, shutil
SDK='/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk'
def detach(p):
    if os.path.islink(p):
        real=os.path.realpath(p); os.remove(p); shutil.copy2(real,p)

# 1) CFAvailability.h: force the noop else branch
cf=SDK+'/System/Library/Frameworks/CoreFoundation.framework/Headers/CFAvailability.h'
detach(cf)
s=open(cf).read()
s2=re.sub(r'#if __has_include\(<Availability\.h>\).*?<AvailabilityMacros\.h>\)',
          '#if 0 /* iconfill */', s, count=1)
print('CFAvailability:', 'patched' if s2!=s else ('already' if 'iconfill' in s else 'NO MATCH'))
open(cf,'w').write(s2)

# 2) os/availability.h: force all availability feature probes to 0 (noop branches)
oa=SDK+'/usr/include/os/availability.h'
detach(oa)
s=open(oa).read()
probes=[r'__has_attribute\(availability\)', r'__has_feature\(attribute_availability[^)]*\)']
n=0
for pat in probes:
    s,k=re.subn(pat,'0',s); n+=k
print('os/availability: patched',n,'probes')
open(oa,'w').write(s)

# 3) Availability.h: same (may already be done)
av=SDK+'/usr/include/Availability.h'
detach(av)
s=open(av).read()
n=0
for pat in probes:
    s,k=re.subn(pat,'0',s); n+=k
print('Availability.h: patched',n,'probes')
open(av,'w').write(s)
