#!/usr/bin/env python3
import re, subprocess
LIB = "/root/star26/s41/work/root/lib/libannibale.dylib"
data = open(LIB, "rb").read()

def cstr(off):
    s = data[off:off+160].split(b"\x00")[0]
    try:
        return s.decode("ascii")
    except Exception:
        return "<bin>"

txt = open("/root/star26/dis-annibale.txt").read().splitlines()
# isolate function
start = None
for i, l in enumerate(txt):
    if "<_annibale_init>:" in l:
        start = i
        break
lines = []
for l in txt[start+1:]:
    if l.strip() == "":
        break
    lines.append(l)

# track adrp reg,0x7000 then add reg,reg,#imm -> resolve string
cur = {}
resolved = []
for l in lines:
    m = re.match(r"\s+([0-9a-f]+):\s+[0-9a-f]+\s+(.*)$", l)
    if not m:
        continue
    addr, ins = m.group(1), m.group(2).strip()
    ma = re.match(r"adrp\s+(x\d+), 0x7000", ins)
    if ma:
        cur[ma.group(1)] = 0x7000
        continue
    ma = re.match(r"add\s+(x\d+), (\w+), #(0x[0-9a-f]+)$", ins)
    if ma and ma.group(2) in cur:
        reg = ma.group(1)
        off = cur[ma.group(2)] + int(ma.group(3), 16)
        if 0 <= off < len(data):
            resolved.append((addr, reg, off, cstr(off)))

# print in order with call targets that follow
print("== string loads in _annibale_init ==")
for addr, reg, off, s in resolved:
    print("  %s  %s <- %#07x  %r" % (addr, reg, off, s[:110]))
