import struct, sys, shutil

SRC = "/root/libannibale-s112.dylib"          # 已含 detectDisplays 正确地址 + ldid 签名
OUT = "/root/libannibale-s114.dylib"
data = bytearray(open(SRC, "rb").read())

# my_detect_displays @0x5370 -> b 0x5514 (tail-call the original implementation, no Metal touch)
at = 0x5370
cur = struct.unpack("<I", data[at:at+4])[0]
if cur != 0xF0000048:                          # adrp x8, 11
    print("ANCHOR FAIL at 0x5370:", hex(cur))
    sys.exit(1)
delta = 0x5514 - at
word = 0x14000000 | ((delta >> 2) & 0x03FFFFFF)
data[at:at+4] = struct.pack("<I", word)
print("patched my_detect_displays -> b 0x5514 (word %#x)" % word)

open(OUT, "wb").write(bytes(data))
print("wrote", OUT, len(data))
