#!/bin/bash
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
cat > /tmp/pac_test.c <<'EOF'
#include <stdint.h>
#if __has_feature(ptrauth_calls)
#include <ptrauth.h>
#endif
typedef int (*fn_t)(int);
int target(int x){ return x*2; }
int call_it(fn_t f){ return f(21); }
#if __has_feature(ptrauth_calls)
void *sign_ptr(void *p){ return ptrauth_sign_unauthenticated(p, ptrauth_key_asia, 0); }
void *strip_ptr(void *p){ return ptrauth_strip(p, ptrauth_key_asia); }
#endif
EOF
echo "=== compile with theos clang-11, arm64e ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$SDK" -O1 -c /tmp/pac_test.c -o /tmp/pac_test.o 2>&1 | head -10
rc=${PIPESTATUS[0]}
echo "RC=$rc"
if [ -f /tmp/pac_test.o ]; then
python3 - /tmp/pac_test.o <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x' % (cpu&0xffffffff,sub&0xffffffff))
PY
echo "=== PAC instructions in disasm? ==="
llvm-objdump -d --macho /tmp/pac_test.o 2>/dev/null | grep -iE 'pacia|autia|pacib|autib|paciasp|autiasp|braa|blraa|ldraa|xpaci' | head -20
echo "=== total PAC instr count ==="
llvm-objdump -d --macho /tmp/pac_test.o 2>/dev/null | grep -icE 'pacia|autia|pacib|autib|braa|blraa|ldraa|xpaci'
fi
