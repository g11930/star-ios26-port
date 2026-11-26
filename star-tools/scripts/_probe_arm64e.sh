#!/bin/bash
# Decisive probe: can this toolchain emit arm64e cpusubtype=0x80000002 dylib?
XC=/root/star26/hackios-xnu-kernel/xnu-deps/host/bin/xnu-clang
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
T=/tmp/arm64e-probe
rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'EOF'
int sb26_probe_add(int a, int b) { return a + b + 42; }
EOF

echo "=== [A] clang18 xnu-clang -arch arm64e ==="
XNU_SDK_VERSION=26.0 "$XC" -arch arm64e -isysroot "$SDK" -miphoneos-version-min=26.0 \
  -dynamiclib -install_name /annibale/lib/libprobe.dylib -Os \
  "$T/probe.c" -o "$T/probe-a.dylib" 2>&1 | head -20
echo "exit=$?"

echo ""
echo "=== [B] clang18 xnu-clang -target arm64e-apple-ios26.0 ==="
/usr/bin/clang -target arm64e-apple-ios26.0 -isysroot "$SDK" \
  -dynamiclib -install_name /annibale/lib/libprobe.dylib -Os \
  "$T/probe.c" -o "$T/probe-b.dylib" 2>&1 | head -20
echo "exit=$?"

echo ""
echo "=== [C] theos clang-11 -arch arm64e ==="
/root/theos/toolchain/linux/iphone/bin/clang-11 -arch arm64e -isysroot "$SDK" -miphoneos-version-min=26.0 \
  -dynamiclib -install_name /annibale/lib/libprobe.dylib -Os \
  "$T/probe.c" -o "$T/probe-c.dylib" 2>&1 | head -20
echo "exit=$?"

echo ""
echo "=== results: Mach-O cputype/cpusubtype ==="
python3 - <<'PY'
import struct, glob, os
for p in sorted(glob.glob("/tmp/arm64e-probe/probe-*.dylib")):
    d=open(p,"rb").read()
    if d[:4]==bytes.fromhex("cffaedfe"):
        cpu,sub=struct.unpack_from("<II",d,4)
        print("%-28s size=%-8d cputype=%s cpusubtype=%s  %s"%(
            os.path.basename(p),len(d),hex(cpu),hex(sub),
            "ARM64e+PAC OK" if (cpu==0x100000c and sub==0x80000002) else "MISMATCH"))
    else:
        print("%-28s NOT MACHO magic=%s"%(os.path.basename(p),d[:4].hex()))
PY
