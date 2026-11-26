import struct, sys

SRC = "/root/libannibale-s114.dylib"
OUT = "/root/libannibale-s118.dylib"
d = bytearray(open(SRC, "rb").read())

def get(off):
    return struct.unpack("<I", d[off:off+4])[0]

# 0x4044 adrp x0,3 ; 0x4048 add x0,x0,#0x100 ; 0x404c bl _printf
if get(0x4044) != 0xF0000000 or get(0x4048) != 0x91040000 or get(0x404c) != 0x94000AB1:
    print("ANCHOR FAIL:", hex(get(0x4044)), hex(get(0x4048)), hex(get(0x404c)))
    sys.exit(1)

# movz w0, #62  (sleep 62s before backboardd's main starts)
d[0x4044:0x4048] = struct.pack("<I", 0x52800000 | (62 << 5) | 0)
d[0x4048:0x404c] = struct.pack("<I", 0xD503201F)          # nop
target = 0x6BB0                                            # stub for _sleep
delta = (target - 0x404C) >> 2
d[0x404C:0x4050] = struct.pack("<I", 0x94000000 | (delta & 0x03FFFFFF))
print("patched constructor: sleep(62) instead of the pid/name printf")

open(OUT, "wb").write(bytes(d))
print("wrote", OUT, len(d))
