import sys, re
tag = sys.argv[1] if len(sys.argv) > 1 else "s128b"
want = sys.argv[2] if len(sys.argv) > 2 else None
t = open("/mnt/c/ios26/%s-live.bin" % tag, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
ls = [l for l in t.split('\n') if 'SpringBoard[' in l]
if want:
    ls = [l for l in ls if 'SpringBoard[%s' % want in l]
ls.sort(key=lambda l: l[:24])
print("lines:", len(ls))
for l in ls[-30:]:
    print(" ", l[:175])
