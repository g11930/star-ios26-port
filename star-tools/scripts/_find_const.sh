#!/bash
python3 - <<'PY'
import struct
p = "/root/old-libannibale.dylib"
d = open(p, "rb").read()
targets = {
    0x1884da264: "CA_DETECT_DISPLAYS",
    0x1882f0908: "VT is_ready",
    0x1882e0c90: "VT ignore_update_p",
    0x1882ddda4: "VT begin_update",
    0x1882c8568: "VT finish_update",
    0x1882e2548: "EAGL renderer",
    0x18835770c: "EAGL render_update",
}
for v, name in targets.items():
    hits = [i for i in range(0, len(d) - 8) if d[i:i+8] == struct.pack("<Q", v)]
    print(f"{name:18s} 0x{v:x}  8字节字面量命中 {len(hits)} 处: {[hex(h) for h in hits[:5]]}")
    hits4 = [i for i in range(0, len(d) - 4) if d[i:i+4] == struct.pack("<I", v & 0xffffffff)]
    print(f"{'':18s}            4字节命中 {len(hits4)} 处: {[hex(h) for h in hits4[:5]]}")
PY
echo "--- 立刻码里的 movz/movk 组合:"
llvm-objdump --macho -d /root/old-libannibale.dylib 2>/dev/null | grep -nE "movk|movz" | grep -iE "0x884d|0xa264|0x1884|0x841a|0x7e18" | head -10
echo "===== DONE ====="
</bash>
