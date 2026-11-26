#!/usr/bin/env python3
"""s82b: remove the remaining three firehose stubs (tracepoint_reserve/
tracepoint_flush/merge_updates) that now collide with the real symbols in
libfirehose_kernel.a.  The stubs existed for the arm64e-kernel link
experiment; the arm64 build resolves these via GOT weak imports (per the
original comment), so deleting them is safe."""
import os
import shutil
import sys

L = "/root/star26/star-native/osfmk/arm64/loader_return.c"
CHECK = "--check" in sys.argv

OLD = '''void __firehose_buffer_tracepoint_reserve(void);
void __firehose_buffer_tracepoint_reserve(void)
{
}

void __firehose_buffer_tracepoint_flush(void);
void __firehose_buffer_tracepoint_flush(void)
{
}

int __firehose_merge_updates(void);
int __firehose_merge_updates(void)
{
	return 0;
}'''
NEW = '''/* s82b: the tracepoint_reserve/flush and merge_updates stubs are gone as
 * well -- libfirehose_kernel.a provides the real ones and the arm64 build
 * links them via GOT weak imports. */'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(L, "r", encoding="utf-8") as f:
        data = f.read()
    if "s82b: the tracepoint_reserve/flush" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = L + ".s82.bak"
    if not os.path.exists(bak):
        shutil.copy2(L, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(L, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] loader_return.c stubs")


if __name__ == "__main__":
    main()
