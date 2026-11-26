paths = [r"C:/ios26/now-032817.bin", r"C:/ios26/now-032636.bin"]

for p in paths:
    raw = open(p, "rb").read()
    text = raw.decode("utf-8", "replace").replace("\x00", "")
    lines = text.splitlines()
    print(f"\n########## {p} ##########")

    # 1) 完整 EXECBGR / libMTL / Compiler / air.ios 行（含完整路径）
    for kw in ["EXECBGR", "libMTL", "Compiler.air", "air.ios26", "non-platform", "EXECDBG: loading /System", "Metal.framework/PlugIns"]:
        hits = [(i, l.strip()) for i, l in enumerate(lines) if kw in l]
        print(f"\n===== {kw} ({len(hits)}) =====")
        for i, l in hits[:15]:
            print(f"  [{i}] {l[:500]}")

    # 2) panic 行前后 30 行窗口（定位 EXECBGR 所在行号）
    anchor = [i for i, l in enumerate(lines) if "EXECBGR" in l or "Metal.framework/PlugIns" in l]
    if anchor:
        a = anchor[0]
        lo, hi = max(0, a - 35), min(len(lines), a + 15)
        print(f"\n===== panic 现场窗口 [{lo}..{hi}] (anchor={a}) =====")
        for i in range(lo, hi):
            mark = ">>" if i in anchor or "panic" in lines[i].lower() or "PXBEXIT" in lines[i] else "  "
            print(f" {mark}[{i}] {lines[i].strip()[:400]}")
