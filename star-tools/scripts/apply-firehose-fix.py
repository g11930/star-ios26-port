#!/usr/bin/env python3
"""
s82 (fix D): bring the kernel firehose buffer back to life.

Chain proven with s79/s80 traplog + logd disassembly:
  stage19 disabled the firehose -> __firehose_buffer_create stub returns
  NULL/0 -> kernel_firehose_addr = 0 -> logd's firehose negotiation via
  LOGBUFFERMAP gets a broken reply -> "firehose libdispatch version
  mismatch (20180226)" / MIG_REPLY_MISMATCH(-301) / "Unexpected kernel
  buffer size" -> brk #1 -> SIGTRAP -> logd dies 16x -> launchd gives up ->
  logd's service port stuck at launchd -> backboardd/SpringBoard os_log
  streaming sync send fills the port -> 98% stall.

Fix:
 1. loader_return.c: delete the __firehose_buffer_create and
    __firehose_kernel_configuration_valid stubs -- the SDK's
    libfirehose_kernel.a provides the REAL implementations
    (___firehose_buffer_create / ___firehose_kernel_configuration_valid,
    verified with llvm-nm) which initialize the buffer header/format that
    logd expects.  K90 never had these stubs.
 2. subr_log.c: oslog_init_firehose() must run its allocation even though
    os_log_disabled() is still true (the kernel's own emission stays off;
    only the buffer + LOGBUFFERMAP for logd come alive).

Idempotent, backed up, strict anchors.  Usage: apply-firehose-fix.py [--check]
"""
import os
import shutil
import sys

L = "/root/star26/star-native/osfmk/arm64/loader_return.c"
S = "/root/star26/star-native/bsd/kern/subr_log.c"
CHECK = "--check" in sys.argv

OLD_STUB = '''void *__firehose_buffer_create(size_t *size);
void *__firehose_buffer_create(size_t *size)
{
	if (size != NULL) {
		*size = 0;
	}
	return NULL;
}

int __firehose_kernel_configuration_valid(int chunks, int pages);
int __firehose_kernel_configuration_valid(int chunks, int pages)
{
	return chunks > 0 && pages > 0;
}'''
NEW_STUB = '''/* s82: the stubs that returned NULL/0 are gone -- the SDK's
 * libfirehose_kernel.a carries the real ___firehose_buffer_create and
 * ___firehose_kernel_configuration_valid, which initialize the buffer
 * header/format that logd's firehose negotiation expects.  With the old
 * stubs the buffer never existed and logd died 16x per boot on
 * "firehose libdispatch version mismatch" (see HANDOFF 10.5.3). */'''

OLD_EARLY = '''	if (os_log_disabled()) {
		printf("Firehose disabled: Logging disabled by ATM\\n");
		return;
	}

	if (!PE_parse_boot_argn("firehose_chunk_count", &__firehose_buffer_kernel_chunk_count, sizeof(__firehose_buffer_kernel_chunk_count))) {'''
NEW_EARLY = '''	/* s82: the firehose buffer must be allocated even though the kernel's
	 * own os_log emission is still disabled (os_log_disabled()): logd's
	 * firehose negotiation via LOGBUFFERMAP needs a real, initialized
	 * buffer, and with kernel_firehose_addr == 0 logd died 16x per boot. */

	if (!PE_parse_boot_argn("firehose_chunk_count", &__firehose_buffer_kernel_chunk_count, sizeof(__firehose_buffer_kernel_chunk_count))) {'''

PATCHES = [
    (L, "stub", OLD_STUB, NEW_STUB),
    (S, "early", OLD_EARLY, NEW_EARLY),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if label == "stub" and "s82: the stubs that returned NULL/0" in data:
            print(f"[skip] {label}")
            continue
        if label == "early" and "s82: the firehose buffer must be allocated" in data:
            print(f"[skip] {label}")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s82.bak"
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
            print(f"[backup] {bak}")
        data = data.replace(old, new, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(data)
        print(f"[patched] {label}")
    print("done")


if __name__ == "__main__":
    main()
