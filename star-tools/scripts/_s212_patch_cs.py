#!/usr/bin/env python3
"""s212: 恢复 mach_loader.c exec 初始页 CS_VALID 保护(star_cs_keep_valid)。
最小改动：1) 加 extern 声明引用 kern_cs.c 全局变量; 2) 无条件清除 => 条件清除。
不引入 s94 备份里已不存在的 star_cs_probe/star_trace 诊断符号。"""
import shutil, sys

P = "/root/star26/star-native/bsd/kern/mach_loader.c"
BAK = P + ".s212-pre"
src = open(P, "r").read()

if "star_cs_keep_valid_init_guard_s212" in src:
    print("ALREADY PATCHED, abort"); sys.exit(1)

shutil.copy2(P, BAK)
print("backup ->", BAK)

# 1) 在 #if __x86_64__ 前插入 extern 声明（该文件顶部函数原型区之后）
anchor = "#if __x86_64__\nextern int bootarg_no32exec;"
assert src.count(anchor) == 1, f"anchor count={src.count(anchor)}"
decl = (
    "/* s212: exec initial-page CS_VALID guard (kern_cs.c defines global) */\n"
    "extern int star_cs_keep_valid;\n"
    "static int star_cs_keep_valid_init_guard_s212;\n"
    "\n"
)
src = src.replace(anchor, decl + anchor, 1)
print("[1] extern decl inserted")

# 2) 无条件清 CS_VALID -> 条件清除
old = "\t\t\t\t\t\t\tresult->csflags &= ~CS_VALID;"
assert src.count(old) == 1, f"csflags clear count={src.count(old)}"
new = (
    "\t\t\t\t\t\t\tif (!star_cs_keep_valid) {\n"
    "\t\t\t\t\t\t\t\tresult->csflags &= ~CS_VALID;\n"
    "\t\t\t\t\t\t\t}"
)
src = src.replace(old, new, 1)
print("[2] CS_VALID clear -> conditional")

open(P, "w").write(src)
print("written", P)
