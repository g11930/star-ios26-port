import struct, subprocess, os, sys

SRC = "/root/old-libannibale.dylib"
OUT = "/root/libannibale-s112.dylib"
data = bytearray(open(SRC, "rb").read())

def enc_movz(imm16, rd=9):
    return 0xD2800000 | ((imm16 & 0xffff) << 5) | rd

def enc_movk(imm16, hw, rd=9):
    return 0xF2800000 | ((hw & 3) << 21) | ((imm16 & 0xffff) << 5) | rd

# expect the old sequence at 0x42e8 / 0x42ec / 0x42f0 -> 0x1884da264 in x9
old = (0x42e8, [enc_movz(0xa264), enc_movk(0x884d, 1), enc_movk(0x0001, 2)])
for off, words in [(0x42e8, old[1])]:
    for i, w in enumerate(words):
        cur = struct.unpack("<I", data[off + 4*i: off + 4*i + 4])[0]
        if cur != w:
            print(f"ANCHOR FAIL at {hex(off+4*i)}: have {hex(cur)} want {hex(w)}")
            sys.exit(1)
print("anchor OK: 0x1884da264 sequence found at 0x42e8")

# new value 0x1841a7e18 -> movz #0x7e18 ; movk #0x841a lsl16 ; movk #0x1 lsl32
new_words = [enc_movz(0x7e18), enc_movk(0x841a, 1), enc_movk(0x0001, 2)]
for i, w in enumerate(new_words):
    data[0x42e8 + 4*i: 0x42e8 + 4*i + 4] = struct.pack("<I", w)
print("patched to 0x1841a7e18")

open(OUT, "wb").write(bytes(data))
print("wrote", OUT, len(data))
