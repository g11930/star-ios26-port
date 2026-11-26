#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage19 -- disable os_log/firehose in this minimal bring-up kernel.

s22 and s23 both died in _log_payload_send+0xf4 -> _memmove+0xa8 with
esr 0x96000045 and a garbage far (0x27c74041 / 0x1f8801f2):
  s22: PE_init_iokit -> printf -> vprintf_internal -> os_log_with_args
  s23: kernel_startup_initialize_upto -> vm_deferred_reclamation_init
       -> os_log_create_impl -> os_log_encoded_metadata -> log_queue_log

Root cause: bsd/kern/subr_log.c defines kernel_firehose_addr = 0, and the
arm64e link stub __firehose_buffer_create() in osfmk/arm64/loader_return.c
returns NULL, so the firehose buffer is NEVER allocated.  firehose_trace()
nevertheless dereferences it and memmove()s into a garbage address.  The tree's
comment claiming "log_payload_send is never called by this bring-up kernel" is
simply wrong.

Fix, two layers, both in libkern/os/log.c:
  1. oslog_disabled starts true and oslog_init() keeps it true, so every
     os_log_create/encoded_* path returns early.  kprintf/IOLog/loader ring
     are unaffected -- those are the channels we actually use.
  2. log_payload_send() returns false immediately while kernel_firehose_addr
     is 0, so any remaining path is dropped instead of faulting.

No architecture / boot-chain / driver change.  Idempotent; --check read-only.
"""
import io
import sys

P = "/root/star26/star-native/libkern/os/log.c"

EDITS = [
    ("default disabled",
     "static SECURITY_READ_ONLY_LATE(bool) oslog_disabled = false;",
     "/* star-native: no firehose kext and __firehose_buffer_create() returns NULL.\n"
     " * Keep os_log off from the very first instruction: vm_deferred_reclamation_init()\n"
     " * calls os_log_create() before the OSLOG startup would evaluate ATM.\n"
     " * kprintf()/IOLog()/the loader log ring are separate channels and stay on. */\n"
     "static SECURITY_READ_ONLY_LATE(bool) oslog_disabled = true;"),

    ("oslog_init",
     "\toslog_disabled = atm_get_diagnostic_config() & ATM_TRACE_DISABLE;",
     "\toslog_disabled = true;   /* star-native: firehose buffer is never allocated */"),

    ("log_payload_send guard",
     "log_payload_send(log_payload_t lp, const void *lp_data, bool use_stream)\n{\n",
     "log_payload_send(log_payload_t lp, const void *lp_data, bool use_stream)\n{\n"
     "\t/* No firehose buffer in this build: __firehose_buffer_create() returns NULL.\n"
     "\t * Letting firehose_trace() run memmove()s into a garbage address. */\n"
     "\tif (kernel_firehose_addr == 0) {\n"
     "\t\treturn false;\n"
     "\t}\n"),
]

MARKER = "star-native: firehose buffer is never allocated"


def main():
    s = io.open(P, encoding="utf-8", errors="surrogateescape").read()
    if "--check" in sys.argv:
        ok = MARKER in s and "if (kernel_firehose_addr == 0)" in s
        print("CHECK", "PASS" if ok else "FAIL")
        return 0 if ok else 1
    if MARKER in s:
        print("already patched")
        return 0
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print("FAIL %s: %d matches" % (name, n))
            return 1
        s = s.replace(old, new, 1)
        print("  %-22s patched" % name)
    io.open(P, "w", encoding="utf-8", errors="surrogateescape").write(s)
    return 0


if __name__ == "__main__":
    sys.exit(main())
