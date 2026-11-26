# -*- coding: utf-8 -*-
# 给 s222 新函数 vm_shared_region_slide_part_v5 补上 plain-auth 写回分支。
# 与旧 slide_page_v5 的 BCM2837 分支一致：arm64 内核无 ptrauth_calls 时，
# authenticated rebase 也要 memcpy 回 plain pointer，否则 auth 指针保持 raw。
p = "/root/star26/star-native/osfmk/vm/vm_shared_region.c"
s = open(p, encoding="utf-8").read()

# 新函数独有的片段：位于 vm_shared_region_slide_part_v5 内、apply 块中的 #endif
old = """\t\t\t\t} else {
\t\t\t\t\tmemcpy(rebaseLocation, &value, sizeof(value));
\t\t\t\t}
#endif /* __has_feature(ptrauth_calls) */
\t\t\t} else {
\t\t\t\tvalue += high8;
\t\t\t\tmemcpy(rebaseLocation, &value, sizeof(value));
\t\t\t}
\t\t}
\t\tif (delta == 0) {
\t\t\tbreak;
\t\t}
\t\tlocation += (uint32_t)delta;
\t\tif (location >= part_start + PAGE_SIZE) {
"""
new = """\t\t\t\t} else {
\t\t\t\t\tmemcpy(rebaseLocation, &value, sizeof(value));
\t\t\t\t}
#else /* !__has_feature(ptrauth_calls) */
\t\t\t\t/* a kernel without pointer authentication sliding an arm64e cache (BCM2837): the plain pointer */
\t\t\t\tmemcpy(rebaseLocation, &value, sizeof(value));
#endif /* __has_feature(ptrauth_calls) */
\t\t\t} else {
\t\t\t\tvalue += high8;
\t\t\t\tmemcpy(rebaseLocation, &value, sizeof(value));
\t\t\t}
\t\t}
\t\tif (delta == 0) {
\t\t\tbreak;
\t\t}
\t\tlocation += (uint32_t)delta;
\t\tif (location >= part_start + PAGE_SIZE) {
"""
cnt = s.count(old)
print("MATCH_COUNT =", cnt)
if cnt != 1:
    raise SystemExit("ABORT: expected exactly 1 match, got %d" % cnt)
s = s.replace(old, new, 1)
open(p, "w", encoding="utf-8").write(s)
print("PATCH_OK: plain-auth branch added to slide_part_v5")
