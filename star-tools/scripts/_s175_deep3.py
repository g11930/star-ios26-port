import re
d=open('/mnt/c/ios26/s175-cpugpu-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')

print('================ ADRENO STEP 4+ TO END OF GPU INIT ================')
for j in range(194, 290):
    print('  L%d: %s' % (j, lines[j][:210]))

print('\n================ ANNI GPU / METAL FINAL STATUS ================')
for pat in [r'adreno: step \d+: (done|fail)', r'adreno.*(ok|success|fail|ready|up|online)',
            r'gpu.*(ready|init.*done|online|powered)',
            r'annibalemetal.*(fail|error|fallback|software|unsupported)',
            r'MTLCompilerService.*(FAIL|error)',
            r'sb26.*(shouldForceBitmapImages|software_icons|bitmap)']:
    ms=[i for i,l in enumerate(lines) if re.search(pat,l,re.I)]
    print('  [%s] %d' % (pat,len(ms)))
    for i in ms[:8]:
        print('    L%d: %s' % (i,lines[i][:200]))

print('\n================ SB26 SOFTWARE ICON BLOCK ================')
for j in range(4905, 4935):
    print('  L%d: %s' % (j, lines[j][:210]))

print('\n================ ICONSERVICES FIRST APPEARANCE / ERRORS ================')
for i,l in enumerate(lines):
    if re.search(r'iconservicesagent\[\d+.*(fail|error|crash|exit|terminat)|iconservices.*(refus|denied|invalid)',l,re.I):
        print('  L%d: %s' % (i,l[:200]))
