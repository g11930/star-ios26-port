paths = [r"C:/ios26/now-032817.bin", r"C:/ios26/s211-now.bin"]
for p in paths:
    raw = open(p, "rb").read()
    text = raw.decode("utf-8", "replace").replace("\x00", "")
    lines = text.splitlines()
    print(f"\n#### {p} ####")
    for kw in ["EXECBGR", "MTLCompiler", "Compiler.air", "air.ios26", "AppleMetalGLRenderer",
               "default.metallib", "newRenderPipelineState", "compiles AIR", "metallib reader",
               "render pipelines", "libMTL", "PlugIns"]:
        hits = [(i, l.strip()) for i, l in enumerate(lines) if kw in l]
        print(f"\n== {kw} ({len(hits)}) ==")
        for i, l in hits[:10]:
            print(f"  [{i}] {l[:350]}")
