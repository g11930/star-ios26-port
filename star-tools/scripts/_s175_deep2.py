import re
d=open('/mnt/c/ios26/s175-cpugpu-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')

def block(title, pat, rng):
    print('\n================ %s ================' % title)
    ms=[i for i,l in enumerate(lines) if re.search(pat,l,re.I)]
    if not ms:
        print('  no match'); return
    i=ms[0]
    for j in range(max(0,i-rng[0]), min(len(lines),i+rng[1])):
        print('  L%d: %s' % (j, lines[j][:210]))

# adreno full init sequence
block('ADRENO GPU INIT', r'adreno: step 1', (0,45))
block('ADRENO CONT', r'adreno: step 3', (0,30))

# CPU: all lines mentioning core/cluster/cpu in first 200 lines
print('\n================ CPU CORE LINES (first 300) ================')
for i,l in enumerate(lines[:300]):
    if re.search(r'core|cpu|cluster|m sphere|core\s*\d', l, re.I):
        print('  L%d: %s' % (i,l[:200]))

# iconservicesagent render detail
print('\n================ ICONSERVICES RENDER ================')
for pat in [r'iconservicesagent.*render', r'iconservicesagent.*(pipe|image|raster|glyph|decode|icon)',
            r'render pipelines:', r'SBCalendarIconImageProvider',
            r'effectiveIconImageAppearance', r'iconservices']:
    ms=[i for i,l in enumerate(lines) if re.search(pat,l,re.I)]
    print('  [%s] %d' % (pat,len(ms)))
    for i in ms[:6]:
        print('    L%d: %s' % (i,lines[i][:200]))

# sb26 hooks
print('\n================ SB26 HOOKS ================')
for i,l in enumerate(lines):
    if re.search(r'^sb26:', l):
        print('  L%d: %s' % (i,l[:200]))
