p = r"C:/ios26/now-032817.bin"
raw = open(p, "rb").read()
text = raw.decode("utf-8", "replace").replace("\x00", "")
lines = text.splitlines()

# 最后 60 行看崩溃点上下文
print("===== 日志最后 60 行 =====")
for i in range(max(0, len(lines) - 60), len(lines)):
    print(f"[{i}] {lines[i].strip()[:350]}")

print("\n===== DataMigration / xpcproxy / platform 相关 =====")
for kw in ["DataMigration", "xpcproxy", "platform", "non-platform", "PXBEXIT", "haltRestart"]:
    hits = [(i, l.strip()) for i, l in enumerate(lines) if kw in l]
    print(f"\n-- {kw} ({len(hits)}) --")
    for i, l in hits[-12:]:
        print(f"  [{i}] {l[:350]}")

print("\n===== 着色器/AIR 成功标志汇总 =====")
for kw in ["triangle:", "annibalemetal[triangle_app", "render pipelines", "metallib", "AIR"]:
    hits = [(i, l.strip()) for i, l in enumerate(lines) if kw in l]
    print(f"\n-- {kw} ({len(hits)}) --")
    for i, l in hits[:15]:
        print(f"  [{i}] {l[:300]}")
