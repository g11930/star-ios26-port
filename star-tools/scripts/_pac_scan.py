"""Scan dyld shared cache slices for PAC instruction-family opcodes.
Counts fixed opcode patterns (no full disasm, fast on multi-GB files).
"""
import os, struct, collections

# dyld shared cache arm64e files
base = "/root/star26/p3/pacscan/cache/System/Library/Caches/com.apple.dyld"
files = [os.path.join(base, f) for f in os.listdir(base) if f.startswith("dyld_shared_cache_arm64e")]
files.sort()
print("cache slices:", [(os.path.basename(f), os.path.getsize(f)) for f in files])

# opcode masks: (name, mask, value) — top-16 halfword patterns
fams = [
  ("PACIA/PACIB/PACDA/PACDB (dac1 op<=7)", 0xfffffc00, 0xdac10000),
  ("PACIA1716/PACIASP etc (hint d503)",     0xfffff0ff, 0xd503201f),
  ("BRAA/BRAB/BLRAA/BLRAB (d71f/d61f)",     0xfffffc00, 0xd71f0800),
  ("RETAA/RETAB (d65f0bff/0fff)",           0xffffffff, 0xd65f0fff),
  ("LDRAA/LDRAB (f8200400)",                0xff200400, 0xf8200400),
  ("XPACI/XPACD (dac143ff/7ff)",            0xfffffc00, 0xdac14000),
  ("AUTIA/AUTIB etc (dac1 op=8..17)",       0xfffffc00, 0xdac10800),
]

CHUNK = 64 * 1024 * 1024
for f in files:
    counts = collections.Counter()
    total = 0
    with open(f, "rb") as fh:
        while True:
            buf = fh.read(CHUNK)
            if not buf: break
            # align to 4 bytes: read as uint32 little-endian at 4-byte steps
            n = len(buf) // 4
            words = struct.unpack_from("<%dI" % n, buf, 0)
            total += n
            for w in words:
                for name, mask, val in fams:
                    if (w & mask) == val:
                        counts[name] += 1
    print("\n===", os.path.basename(f), "words:", total)
    for name, _m, _v in fams:
        print(f"  {name:42s} {counts[name]}")
