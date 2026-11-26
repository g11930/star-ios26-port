p = r"C:/ios26/now-032817.bin"
raw = open(p, "rb").read()
text = raw.decode("utf-8", "replace").replace("\x00", "")
lines = text.splitlines()

# 1) triangle_app 着色器编译全流程 (13300-13600)
print("===== triangle 着色器编译全流程 [13330..13560] =====")
for i in range(13330, min(13560, len(lines))):
    l = lines[i].strip()
    if l:
        print(f"[{i}] {l[:300]}")

# 2) 所有 EXECDBG/EXECBGR 行
print("\n===== 所有 EXECDBG/EXECBGR/EXEC 加载行 =====")
for i, l in enumerate(lines):
    ls = l.strip()
    if ls.startswith("EXEC") or "EXECBGR" in ls or "EXECDBG" in ls:
        print(f"[{i}] {ls[:300]}")

# 3) 所有含 Compiler / air / PlugIns 的行
print("\n===== Compiler / air / PlugIns 相关 =====")
for i, l in enumerate(lines):
    ls = l.strip()
    if any(k in ls for k in ("Compiler", "compiler", "air.", "PlugIns", "MTL", "shader library")):
        print(f"[{i}] {ls[:300]}")
