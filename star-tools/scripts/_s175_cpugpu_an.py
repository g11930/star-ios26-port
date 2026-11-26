import re
p='/mnt/c/ios26/s175-cpugpu-log.bin'
d=open(p,'rb').read().decode('utf-8','replace').replace('\0','')
lines=d.split('\n')
print('log bytes', len(d), 'lines', len(lines))

def section(title, patterns, ctx_before=0, ctx_after=0, maxhit=6):
    print('\n================ %s ================' % title)
    total=0
    for pat in patterns:
        hits=[(i,l) for i,l in enumerate(lines) if re.search(pat,l,re.I)]
        total+=len(hits)
        if not hits:
            print('  [%s] 0' % pat); continue
        print('  [%s] %d hits' % (pat,len(hits)))
        for i,l in hits[:maxhit]:
            print('    L%d: %s' % (i,l[:200]))
            for j in range(i+1,min(len(lines),i+1+ctx_after)):
                print('        > %s' % lines[j][:180])
    return total

# CPU core startup
section('CPU CORES', [
    r'cores for the kernel',
    r'core \d+: the firmware',
    r'the kernel will run on core',
    r'ARM_CPU|cpu\d+.*start|cpus=|bootcpu',
    r'start_cpu|cpu.*online|cpu.*up',
], ctx_after=3)

# CPU-related errors
section('CPU ERRORS', [
    r'cpu.*(fail|error|panic|timeout|stuck)',
    r'psci|PSCI',
    r'secondary.*(fail|timeout)',
])

# GPU / Metal backend
section('GPU / METAL BACKEND', [
    r'actual_backend',
    r'default_before',
    n if False else r'registration (failed|completed|device)',
    r'backend mismatch',
    r'AnnibaleMetal|annibalemetal|sbmetal26',
    r'METAL|Metal.*(init|device|backend)',
], ctx_after=2, maxhit=4)

# graphics / render
section('GRAPHICS / RENDER', [
    r'IONDRV|DRM|drm|msm|adreno|a6\d\d|a7\d\d|kgsl',
    r'GPU.*(firmware|fw|init|clock|power)',
    r'gfx|GFX',
    r'IOSurface|surface swap|panel swap',
], maxhit=3)

# icon / app / SBUI
section('ICON / APP RENDER', [
    r'icon',
    r'SBIcon|IconView|icon.*(load|image|render|cache)',
    r'SLT|SpringBoard.*(icon|app|launch)',
    r'placeholder|generic.*icon|default.*icon',
    r'app.*(fail|missing|not found)',
], maxhit=5)

# timestamp span
ts=re.findall(r'(\d\d:\d\d:\d\d)\.\d+\+0800',d)
print('\nTIMESTAMP first=%s last=%s' % (ts[0] if ts else '-', ts[-1] if ts else '-'))
