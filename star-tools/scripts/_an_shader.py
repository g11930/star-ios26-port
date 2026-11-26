import re, sys

paths = [
    r"C:/ios26/now-032817.bin",
    r"C:/ios26/now-032636.bin",
    r"C:/ios26/s211-now.bin",
]

keys = ["EXECBGR", "Metal.framework", "Compiler", "air.ios", "non-platform",
        "libMTL", "shader", "Shader", "MTLCompiler", "METAL", "metal",
        "page_in mach_loader", "csb_platform", "platform binary"]

for p in paths:
    try:
        raw = open(p, "rb").read()
    except Exception as e:
        print(f"===== {p}: {e} =====")
        continue
    text = raw.decode("utf-8", "replace").replace("\x00", "")
    lines = text.splitlines()
    print(f"\n########## {p}  ({len(raw)} bytes, {len(lines)} lines) ##########")
    for kw in keys:
        hits = [(i, l.strip()) for i, l in enumerate(lines) if kw in l]
        if not hits:
            continue
        print(f"\n===== {kw}  ({len(hits)}) =====")
        show = hits if len(hits) <= 20 else hits[:20] + [("...", f"...还有 {len(hits)-20} 条...")]
        for i, l in show:
            # 每行最多 400 字符，保留完整路径
            print(f"  [{i}] {l[:400]}")
