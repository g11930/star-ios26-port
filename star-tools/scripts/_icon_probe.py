import re
d=open('/mnt/c/ios26/s175-cpugpu-log.bin','rb').read().decode('utf-8','replace').replace('\0','')
for k in ['icon rendering Metal device', 'software_icons_installed', 'SBIconImageView',
          'shouldForceBitmapImages', 'MTLCreateSystemDefaultDevice', 'hasGlass',
          'SBHCalendarApplicationIcon', 'Calendar', 'path_distance_fragment']:
    print('%-34s %d' % (k, d.count(k)))
# all sb26 lines
print('\n--- sb26 lines ---')
for l in d.split('\n'):
    if 'sb26:' in l:
        print(' ', l.strip()[:200])
