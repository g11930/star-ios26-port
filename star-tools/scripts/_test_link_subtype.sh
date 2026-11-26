#!/bin/bash
TC=/root/theos/toolchain/linux/iphone/bin
cat > /tmp/linktest.c <<'EOF'
#include <stdint.h>
#if __has_feature(ptrauth_calls)
#include <ptrauth.h>
#endif
int add(int a,int b){return a+b;}
#if __has_feature(ptrauth_calls)
void *sig(void *p){ return ptrauth_sign_unauthenticated(p, ptrauth_key_asia, 0); }
#endif
EOF
echo "=== clang-11 compile + ld64 link ==="
$TC/clang -target arm64e-apple-ios16.5 -O1 -dynamiclib -install_name /tmp/linktest.dylib \
  -fuse-ld="$TC/ld" /tmp/linktest.c -o /tmp/linktest.dylib 2>&1 | tail -8
echo "=== linked dylib cpusubtype ==="
python3 - /tmp/linktest.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x (0x80000002=compliant)' % (cpu&0xffffffff,sub&0xffffffff))
PY
echo "=== PAC instrs ==="
llvm-objdump -d --macho /tmp/linktest.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci'
