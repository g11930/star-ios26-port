#!/usr/bin/env python3
"""Find image headers by searching for their LC_ID_DYLIB install-name strings;
parse the header at the string's referencing Mach-O."""
import glob
import os
import re
import struct
import sys

sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, mappings

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(p for p in glob.glob(D + "/dyld_shared_cache_arm64e.*")
    if re.search(r"dyld_shared_cache_arm64e\.\d+$", p))


def vm_to_file(vm):
    for addr, size, foff, p in mappings:
        if addr <= vm < addr + size:
            return p, foff + (vm - addr)
    return None, None


def file_to_vm(p, off):
    for addr, size, foff, pf in mappings:
        if pf == p and foff <= off < foff + size:
            return addr + (off - foff)
    return None


TARGETS = [b"/usr/lib/system/libdispatch.dylib",
           b"/usr/lib/system/libxpc.dylib",
           b"/System/Library/Frameworks/CoreFoundation.framework/"
           b"CoreFoundation"]

for p in files:
    data = open(p, "rb").read()
    for t in TARGETS:
        i = 0
        while True:
            i = data.find(t, i)
            if i < 0:
                break
            vm = file_to_vm(p, i)
            if vm:
                # the LC_ID_DYLIB name is inside a header; scan back up to 8K
                # for the Mach-O magic and validate by re-finding the name
                # within the header
                back = R.read(vm - 0x2000, 0x2000 + 0x1000)
                if back:
                    j = back.rfind(b"\xcf\xfa\xed\xfe", 0,
                        0x2000 + 40)
                    if j >= 0:
                        hvm = vm - 0x2000 + j
                        m = R.read(hvm, 0x1000) or b""
                        if m[:4] == b"\xcf\xfa\xed\xfe" and t in m:
                            ncmds = struct.unpack_from("<I", m, 16)[0]
                            o = 32
                            tva = tsz = None
                            for _ in range(ncmds):
                                cmd, size = struct.unpack_from(
                                    "<II", m, o)
                                if cmd == 0x19 and m[o + 8:o + 24].\
                                        split(b"\0")[0] == b"__TEXT":
                                    tva = struct.unpack_from(
                                        "<Q", m, o + 24)[0]
                                    tsz = struct.unpack_from(
                                        "<Q", m, o + 32)[0]
                                o += size
                            print(f"{t.decode()}: header vm 0x{hvm:x} "
                                f"__TEXT=0x{tva:x} size=0x{tsz:x} "
                                f"({p.split('/')[-1]})")
            i += 1
