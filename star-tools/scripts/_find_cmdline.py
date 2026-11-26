#!/usr/bin/env python3
d = open('/mnt/c/ios26/s200-boot.img', 'rb').read()
for tok in (b'fb_diff=1', b'fb_diff', b'touch_lat=1', b'touchscreen=1'):
    i = d.find(tok)
    print(tok, i, d[max(0,i-60):i+40] if i >= 0 else '')
