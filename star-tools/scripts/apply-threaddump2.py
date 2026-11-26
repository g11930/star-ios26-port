#!/usr/bin/env python3
"""
s78: name every backtrace frame at dump time.

The s77 dump prints raw user pcs; without the 23G90 dyld cache on hand the
frames cannot be symbolized offline.  But annibale_task_region_image()
(bsd/dev/star/annibale_threads.c) resolves ANY user address to its image
(vnode namecache) -- the cache, the main binary and dyld-mapped injected
libraries all have vnodes.  Patch the osfmk half's annibale_td_backtrace()
to carry the task through and print, for the first 8 frames of each
thread, a "fr" line "<image>+<offset-in-region>" right after the bt line.
annibale_tl caps lines at ~256 chars, so the names go on separate lines.

Read-only, idempotent, backup, strict anchors.
Usage: python3 apply-threaddump2.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/annibale_threads.c"
CHECK = "--check" in sys.argv

OLD_SIG = '''static void
annibale_td_backtrace(int pid, vm_map_t map, thread_t thread)
{'''
NEW_SIG = '''extern int annibale_task_region_image(task_t task, uint64_t addr,
    char *name, uint32_t namelen, uint64_t *start, uint64_t *end);

static void
annibale_td_backtrace(task_t task, int pid, vm_map_t map, thread_t thread)
{'''

OLD_LOOP = '''\t\tfor (unsigned int i = 0; i < ANNIBALE_TD_LINE_FRAMES && at < count && n > 0 && (size_t)n < sizeof(line); i++, at++) {
\t\t\tn += snprintf(line + n, sizeof(line) - (size_t)n, " %lx", (unsigned long)frames[at]);
\t\t}
\t\tannibale_tl("%s%s\\n", line, at >= count && (info.btui_info & BTI_TRUNCATED) ? " +" : "");'''
NEW_LOOP = OLD_LOOP + '''

\t\t/* s78: name the innermost frames (cache binary/injected lib + offset)
\t\t * on separate lines -- annibale_tl truncates long lines. */
\t\tfor (unsigned int i = 0; i < 8 && i < count; i++) {
\t\t\tchar fname[64];
\t\t\tuint64_t fstart = 0;

\t\t\tif (annibale_task_region_image(task, frames[i], fname,
\t\t\t    sizeof(fname), &fstart, NULL) == 1) {
\t\t\t\tannibale_tl("tl: td %d tid %llu fr %u %s+%llx\\n",
\t\t\t\t    pid, (unsigned long long)thread_tid(thread), i,
\t\t\t\t    fname, (unsigned long long)(frames[i] - fstart));
\t\t\t} else {
\t\t\t\tannibale_tl("tl: td %d tid %llu fr %u ?%lx\\n",
\t\t\t\t    pid, (unsigned long long)thread_tid(thread), i,
\t\t\t\t    (unsigned long)frames[i]);
\t\t\t}
\t\t}'''

OLD_CALL = '''\tfor (unsigned i = 0; i < kept; i++) {
\t\tannibale_td_backtrace(pid, map, held[i]);'''
NEW_CALL = '''\tfor (unsigned i = 0; i < kept; i++) {
\t\tannibale_td_backtrace(task, pid, map, held[i]);'''

PATCHES = [
    ("sig",  OLD_SIG,  NEW_SIG,  "annibale_task_region_image(task_t task"),
    ("loop", OLD_LOOP, NEW_LOOP, "fr %u %s+%llx"),
    ("call", OLD_CALL, NEW_CALL, "annibale_td_backtrace(task, pid, map, held[i])"),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "fr %u %s+%llx" in data:
        print("[skip] already applied")
        return
    for label, old, new, token in PATCHES:
        if token in data and label != "loop":
            print(f"[skip] {label}")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        data = data.replace(old, new, 1)
    if not CHECK:
        bak = K + ".s78.bak"
        if not os.path.exists(bak):
            shutil.copy2(K, bak)
            print(f"[backup] {bak}")
        with open(K, "w", encoding="utf-8") as f:
            f.write(data)
        print("[patched] all")
    print("done")


if __name__ == "__main__":
    main()
