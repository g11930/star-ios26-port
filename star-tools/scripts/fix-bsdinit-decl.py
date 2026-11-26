import io

p = "/root/star26/star-native/bsd/kern/bsd_init.c"
s = io.open(p, encoding="utf-8").read()

blk = "\n/* star stage 10: the loader's bring-up checkpoint */\nextern void loader_checkpoint(uint64_t);\n"
while blk in s:
    s = s.replace(blk, "", 1)

lines = s.split("\n")
# the first run of #include lines, near the top
first = next(i for i, l in enumerate(lines) if l.startswith("#include"))
last = first
while last + 1 < len(lines) and (lines[last + 1].startswith("#include") or lines[last + 1].strip() == ""):
    last += 1
lines.insert(last + 1, "\n/* star stage 10: the loader's bring-up checkpoint */\nextern void loader_checkpoint(uint64_t);")
io.open(p, "w", encoding="utf-8").write("\n".join(lines))

out = io.open(p, encoding="utf-8").read()
for i, l in enumerate(out.split("\n"), 1):
    if "loader_checkpoint" in l:
        print("%4d %s" % (i, l))
