#!/bin/bash
TC=/root/theos/toolchain/linux/iphone/bin
T=/root/theos/sdks/iPhoneOS16.5.sdk
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$T" -O1 -dynamiclib -install_name /tmp/linktest.dylib \
  -fuse-ld="$TC/ld" -L"$T/usr/lib" /tmp/linktest.c -o /tmp/linktest.dylib 2>&1 | tail -6
echo "=== linked ==="
python3 - /tmp/linktest.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x (0x80000002=compliant)' % (cpu&0xffffffff,sub&0xffffffff))
PY
echo -n 'PAC count: '; llvm-objdump -d --macho /tmp/linktest.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci'
