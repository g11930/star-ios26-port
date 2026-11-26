import sys, re
p = sys.argv[1]
d = open(p, 'rb').read()
t = d.decode('utf-8', 'replace').replace('\0', '')
print("size", len(t))
pats = ["annibale lib loaded", "start HID system", "start GS", "start window server",
        "Initializing CAWindowServer", "handshake request from", "Receiving handshake",
        "Removing all cached process handles", "backboardd[", "runningboardd[",
        "triald[", "P28FAULT", "P28EXIT", "jetsam", "Unable to deserialize"]
for x in pats:
    print("  %-40s %d" % (x, t.count(x)))
print("\n--- backboardd PIDs ---")
pids = sorted(set(re.findall(r'backboardd\[(\d+)', t)), key=int)
print(pids)
print("\n--- runningboardd PIDs ---")
rp = sorted(set(re.findall(r'runningboardd\[(\d+)', t)), key=int)
print(rp)
print("\n--- key timeline lines ---")
for l in t.split('\n'):
    if any(k in l for k in ('start HID', 'start GS', 'start window', 'CAWindowServer',
                            'handshake', 'Removing all cached', 'annibale lib loaded',
                            'triald[', 'P28FAULT', 'Unable to deserialize')):
        print("  ", l[:185])
