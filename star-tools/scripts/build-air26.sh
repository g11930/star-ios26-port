#!/bin/bash
# P26: build libannibaleair.dylib for arm64e from the patched Mesa 26.2.5 tree.
# Prints a stage banner before each step so a failure names the stage.
set -e

B=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa
M=$B/mesa-26.2.5
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
LD64=/root/theos/toolchain/linux/iphone/bin/ld
INTOOL=/root/theos/toolchain/linux/iphone/bin/install_name_tool
BIN=/root/star26/bin
BUILD=$B/build-star26
OUT=${OUT_DIR:-/root/star26/p26}
mkdir -p "$BIN" "$OUT"

# --- compiler wrappers: the cross file passes -arch arm64, which would win ---
# --ld-path only on a link: meson's checks compile with
# -Werror=unused-command-line-argument, and an unused --ld-path fails the check
# (it silently said "no struct timespec" and the c11 headers then redefined it).
write_wrapper() {
	local out=$1 comp=$2
	cat > "$out" <<EOF
#!/bin/bash
out=()
skip=0
link=1
for a in "\$@"; do
	if [ "\$skip" = 1 ]; then skip=0; continue; fi
	if [ "\$a" = "-arch" ]; then skip=1; continue; fi
	if [ "\$a" = "-c" ] || [ "\$a" = "-S" ] || [ "\$a" = "-E" ]; then link=0; fi
	out+=("\$a")
done
if [ "\$link" = 1 ]; then
	exec /usr/bin/$comp -target arm64e-apple-ios16.5 --ld-path=/root/theos/toolchain/linux/iphone/bin/ld "\${out[@]}"
fi
exec /usr/bin/$comp -target arm64e-apple-ios16.5 "\${out[@]}"
EOF
	chmod +x "$out"
}
write_wrapper "$BIN/cc-arm64e" clang
write_wrapper "$BIN/cxx-arm64e" clang++
chmod +x "$BIN/cc-arm64e" "$BIN/cxx-arm64e"

echo "=== STAGE 1: wrapper smoke test ==="
cd /tmp
printf 'int f(void){return 1;}\n' > p26t.c
/root/star26/bin/cc-arm64e -isysroot "$SDK" -O1 -c p26t.c -o p26t.o
file p26t.o

echo "=== STAGE 2: venv + meson ==="
if [ ! -x "$B/venv/bin/meson" ]; then
	python3 -m venv "$B/venv"
	"$B/venv/bin/pip" -q install mako pyyaml packaging "meson==1.12.1"
fi
"$B/venv/bin/meson" --version

echo "=== STAGE 3: cross file ==="
cat > "$B/cross-star26.ini" <<INI
[binaries]
c = ['$BIN/cc-arm64e', '-isysroot', '$SDK']
cpp = ['$BIN/cxx-arm64e', '-isysroot', '$SDK', '-fuse-cxa-atexit']
objc = ['$BIN/cc-arm64e', '-isysroot', '$SDK']
ar = 'llvm-ar'
ranlib = 'llvm-ranlib'
strip = 'llvm-strip'
pkg-config = 'false'

[host_machine]
system = 'darwin'
subsystem = 'ios'
cpu_family = 'aarch64'
cpu = 'arm64e'
endian = 'little'

[properties]
needs_exe_wrapper = true
INI

echo "=== STAGE 4: meson setup ==="
cd "$B"
if [ "${WIPE:-}" = 1 ]; then rm -rf "$BUILD"; fi
if [ ! -f "$BUILD/build.ninja" ]; then
	PATH="$B/venv/bin:$PATH" meson setup "$BUILD" "$M" --cross-file cross-star26.ini --wrap-mode=nofallback \
		--prefix=/annibale --libdir=lib --buildtype=release -Db_ndebug=true \
		-Dplatforms= -Dgallium-drivers=softpipe,freedreno -Dfreedreno-kmds=msm -Dvulkan-drivers= \
		-Dglx=disabled -Degl=disabled -Dgbm=disabled -Dosmesa=true -Dllvm=disabled \
		-Dshared-glapi=enabled -Dgles1=disabled -Dgles2=enabled -Dopengl=true \
		-Dzstd=disabled -Dxmlconfig=disabled -Dexpat=disabled -Dshader-cache=disabled -Dvalgrind=disabled \
		-Dlibunwind=disabled -Dglvnd=disabled -Dvideo-codecs= -Dtools= -Dgallium-va=disabled \
		-Dlmsensors=disabled -Dbuild-tests=false > meson-setup-star26.log 2>&1 || {
		echo "MESON SETUP FAILED"; tail -40 meson-setup-star26.log; exit 1; }
fi
echo "meson setup ok"
grep -n 'has symbol "struct timespec"\|has symbol "thrd_create"' "$BUILD/meson-logs/meson-log.txt" | tail -3 || true

echo "=== STAGE 5: ninja libannibaleair ==="
PATH="$B/venv/bin:$PATH" ninja -C "$BUILD" src/gallium/drivers/freedreno/libannibaleair.dylib > ninja-star26.log 2>&1 || {
	echo "NINJA FAILED"; grep -n "error:" ninja-star26.log | head -30; exit 1; }

echo "=== STAGE 6: strip + id ==="
RAW=$BUILD/src/gallium/drivers/freedreno/libannibaleair.dylib
ls -la "$RAW"
llvm-strip -x -o "$OUT/libannibaleair.dylib" "$RAW"
"$INTOOL" -id /annibale/lib/libannibaleair.dylib "$OUT/libannibaleair.dylib"
ls -la "$OUT/libannibaleair.dylib"
llvm-objdump --macho --private-headers "$OUT/libannibaleair.dylib" 2>/dev/null | awk '/LC_ID_DYLIB/{f=1} f&&$1=="name"{print "install name:", $2; exit}'

echo "=== STAGE 7: exports ==="
llvm-nm -gU "$OUT/libannibaleair.dylib" | awk '{print $NF}' | grep -c '^rwa_' || true
llvm-nm -gU "$OUT/libannibaleair.dylib" | awk '{print $NF}' | LC_ALL=C sort > "$OUT/exports-rwa.txt"
head -5 "$OUT/exports-rwa.txt"

echo "=== STAGE 8: cpu subtype before flip ==="
python3 - "$OUT/libannibaleair.dylib" <<'PY'
import struct, sys
p = sys.argv[1]
d = bytearray(open(p, 'rb').read())
magic, cpu, sub, ft, ncmds = struct.unpack_from('<IiiII', d, 0)
print('magic %#x cputype %#x cpusubtype %#x filetype %d ncmds %d' % (magic, cpu, sub, ft, ncmds))
PY

echo "=== DONE ==="
