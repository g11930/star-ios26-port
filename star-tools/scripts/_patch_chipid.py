p = '/root/star26/star-native/bsd/dev/star/annibale_adreno.c'
s = open(p).read()
import re
m = re.search(r'#define GPU_CHIP_ID\s+0x[0-9a-fA-F]+ull', s)
assert m, 'define not found'
new = ('#define GPU_CHIP_ID             0x060600ffull   /* a660 as freedreno encodes it:\n'
       '                                                 * GPUId(660) -> core 6, major 6, minor 0, 0xff */')
s = s[:m.start()] + new + s[m.end():]
open(p, 'w').write(s)
print(open(p).read()[m.start():m.start() + 200].split('\n')[0:3])
