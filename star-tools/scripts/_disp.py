import re
t = open('/tmp/s126b.txt', 'rb').read().decode('utf-8', 'replace')
keys = ['first_frame', 'commit', 'swap', 'CAMetalLayer', 'IOSurface', 'render',
        'display0', 'disp0', 'AppleH1CLCD', 'MiniIOMobileFramebuffer', 'MIF',
        'start window server', 'Initializing CAWindowServer', 'StartWindowServer',
        'no display', 'Display:']
for k in keys:
    print("%-32s %d" % (k, t.count(k)))
print("\n--- display / window server lines ---")
for l in t.split('\n'):
    if any(k in l for k in ('StartWindowServer', 'CAWindowServer', 'Display', 'disp0', 'MIF', 'screen')):
        print(" ", l[:190])
