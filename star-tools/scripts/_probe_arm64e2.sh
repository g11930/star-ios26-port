#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
XC=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/xnu-clang
LD=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/ld64
T=/tmp/arm64e-probe2
rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'EOF'
int sb26_probe_add(int a, int b) { return a + b + 42; }
EOF
echo "ld64 exists: $([ -e "$LD" ] && echo YES || echo NO)"

run() {
  name=$1; shift
  echo "=== $name ==="
  XNU_SDK_VERSION=26.0 "$XC" -target arm64e-apple-ios26.0 -isysroot "$SDK" \
    --ld-path="$LD" -dynamiclib -install_name /annibale/lib/libprobe.dylib -Os \
    "$@" "$T/probe.c" -o "$T/$name.dylib" 2>&1 | head -8
  echo "  exit=${PIPESTATUS[0]}"
}

run p0
run p1 -fptrauth-calls
run p2 -fptrauth-calls -fptrauth-returns -fptrauth-indirect-gotos -fptrauth-auth-traps
run p3 -fptrauth-calls -fptrauth-function-pointer-type-discrimination -fptrauth-vtable-pointer-type-discrimination
run p4 -fptrauth-calls -fptrauth-returns -fptrauth-indirect-gotos -fptrauth-auth-traps \
       -fptrauth-function-pointer-type-discrimination -fptrauth-vtable-pointer-type-discrimination

echo ""
echo "=== results ==="
python3 - <<'PY'
import struct, glob, os
for p in sorted(glob.glob("/tmp/arm64e-probe2/p*.dylib")):
    d=open(p,"rb").read()
    if d[:4]==bytes.fromhex("cffaedfe"):
        cpu,sub=struct.unpack_from("<II",d,4)
        ok = (cpu==0x100000c and sub==0x80000002)
        print("%-12s size=%-8d cpu=%s sub=%s  %s"%(
            os.path.basename(p),len(d),hex(cpu),hex(sub),"OK arm64e+PAC" if ok else "sub wrong"))
    else:
        print("%-12s NOT MACHO %s"%(os.path.basename(p),d[:4].hex()))
PY
