import sys
from struct import unpack_from

W, H = 1440, 3200

def analyze(path):
    d = open(path, 'rb').read()
    n = 0
    minx, miny, maxx, maxy = W, H, -1, -1
    step = 4
    for y in range(0, H, step):
        row = y * W * 3
        for x in range(0, W, step):
            o = row + x * 3
            b, g, r = d[o], d[o + 1], d[o + 2]
            if b or g or r:
                n += 1
                if x < minx: minx = x
                if x > maxx: maxx = x
                if y < miny: miny = y
                if y > maxy: maxy = y
    print(path, 'sampled-nonzero', n, 'box', (minx, miny, maxx, maxy))
    return d

a = analyze('/mnt/c/ios26/s155e-frame.raw')
b = analyze('/mnt/c/ios26/s155g-frame.raw')
diff = sum(1 for i in range(0, len(a), 3) if a[i:i+3] != b[i:i+3])
print('differing sampled pixels(bytes):', diff)
