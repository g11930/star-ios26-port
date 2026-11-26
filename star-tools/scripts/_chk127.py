import sys, re
tag = sys.argv[1] if len(sys.argv) > 1 else "s127a"
fr = "/mnt/c/ios26/%s-frame.raw" % tag
lg = "/mnt/c/ios26/%s-live.bin" % tag
try:
    d = open(fr, 'rb').read()
    print("%s frame nonzero: %d of %d" % (tag, sum(1 for b in d if b), len(d)))
except FileNotFoundError:
    print("no frame")
t = open(lg, 'rb').read().decode('utf-8', 'replace').replace('\0', '')
print("log size", len(t))
keys = ['start window server', 'Initializing CAWindowServer', 'start HID', 'swap #', 'P34:',
        'Received handshake request from', 'Unable to load jetsam', 'P28FAULT', 'frames flipped']
for k in keys:
    print("  %-34s %d" % (k, t.count(k)))
pids = sorted(set(int(x) for x in re.findall(r'Received handshake request from (\d+)', t)))
print("handshake answered pids:", pids)
sb = [l for l in t.split('\n') if 'SpringBoard[' in l]
sb.sort(key=lambda l: l[:24])
print("SpringBoard lines:", len(sb))
for l in sb[-6:]:
    print("  ", l[:160])
