import sys, os
sys.path.insert(0, '/root/star-build/tools/apfs')
import apfs

p = '/root/star26/s111/root19.apfs'
c = apfs.Container(p)
v = c.volumes()[0]

def ls(path, limit=25):
    try:
        node = v.lookup(path)
    except Exception as e:
        print(path, 'ERR', e); return
    print('---', path, '---')
    try:
        kids = v.listdir(node) if hasattr(v, 'listdir') else None
    except Exception as e:
        kids = None
        print('listdir err', e)
    if kids:
        for k in list(kids)[:limit]:
            print('  ', k)

for d in ['/System/Library/Frameworks/ImageIO.framework',
          '/System/Library/Frameworks/ImageIO.framework/Versions/A',
          '/System/Library/Frameworks/CoreGraphics.framework']:
    ls(d, 12)

print('--- icon caches / MobileIcons ---')
for d in ['/System/Library/PrivateFrameworks/MobileIcons.framework',
          '/System/Library/PrivateFrameworks/IconServices.framework',
          '/var/mobile/Library/Caches']:
    ls(d, 10)
