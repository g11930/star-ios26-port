import re

def load(p):
    return open(p,'rb').read().decode('utf-8','replace').replace('\0','')

def show(label, d):
    print('\n================ %s ================' % label)
    for pat in [r'sbmetal26:.*', r'say \d+ sbmetal26:.*', r'default_before=.*',
                r'actual_backend=.*', r'P34: panel swap \d+.*', r'P34: surface swap \d+.*',
                r'first_frame.*', r'WindowServer.*display power state.*']:
        ms = re.findall(pat, d)
        if ms:
            print('  [%s] %d hits' % (pat, len(ms)))
            for m in ms[:4]:
                print('      '+m[:200])

s173 = load('/mnt/c/ios26/s173d-live.bin')
s175 = load('/mnt/c/ios26/s175-log.bin')
print('s173 bytes', len(s173), '  s175 bytes', len(s175))
show('s173 GOOD', s173)
show('s175 BAD', s175)

# key counters for both
print('\n================ COUNTERS ================')
keys=['error=22','cs_flags=26000000','NOT_CODESIGNED',
      'registration device=1','registration device=0','registration failed',
      'backend mismatch','IOAcceleratorES unavailable',
      'WindowServer','first_frame','backboardd','SpringBoard',
      'panel swap','surface swap','first ff000000']
for k in keys:
    print('  %-32s s173=%-6d s175=%-6d' % (k, s173.count(k), s175.count(k)))
