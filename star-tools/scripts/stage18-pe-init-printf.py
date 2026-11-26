#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage18 -- remove the last real printf() from the early pexpert boot path.

s22 panic (fully symbolized):
    pc  = _memmove +0xa8
    lr  = _log_payload_send +0xf4
    backtrace: _PE_init_iokit+0x40 -> _printf+0x24 -> _vprintf_internal+0x8c
               -> _os_log_with_args+0x84 -> _os_log_create+0xcb
               -> _log_queue_log+0x5c -> _log_payload_send+0xf4 -> _memmove
    esr 0x96000045 (EL1 data abort, write), far 0x27c74041 (garbage pointer)

CONFIG_NO_PRINTF_STRINGS defines an empty printf() macro in
osfmk/kern/misc_protos.h and bsd/libkern/libkern.h, but pexpert/arm/pe_init.c
includes neither, so `printf("iBoot version: %s\\n", ...)` in PE_init_iokit()
resolves to the REAL printf -> os_log/firehose path, which is not initialized
in this minimal kernel.  It aborts before bsd_init, so no milestone or trace
line can ever be emitted.

Fix: make printf() a no-op in this TU only, after all includes.  The calls are
purely informational banners.  kprintf() is deliberately left alone: it goes
through PE_kputc -> loader_log_putc and is the channel that already works.

Idempotent; --check is read-only.  No architecture or boot-chain change.
"""
import io
import sys

P = "/root/star26/star-native/pexpert/arm/pe_init.c"
ANCHOR = "#include <os/overflow.h>\n"

BLOCK = '''
/*
 * star-native: CONFIG_NO_PRINTF_STRINGS makes printf() an empty macro in
 * osfmk/kern/misc_protos.h and bsd/libkern/libkern.h, but this file includes
 * neither.  Without the macro, PE_init_iokit()'s informational banner reaches
 * the real printf -> vprintf_internal -> os_log_with_args -> log_payload_send
 * -> memmove path, whose firehose queue is not set up in this minimal kernel
 * (s22: data abort at _memmove+0xa8, far=0x27c74041).  Keep the intent of the
 * configuration here too.  kprintf() is NOT touched: it goes to PE_kputc ->
 * loader_log_putc, which is the working log channel.
 */
#undef printf
#define printf(fmt, ...) do {} while (0)
'''

MARKER = "star-native: CONFIG_NO_PRINTF_STRINGS"


def main():
    s = io.open(P, encoding="utf-8", errors="surrogateescape").read()
    if "--check" in sys.argv:
        print("CHECK", "PASS" if MARKER in s else "FAIL (pe_init.c printf still live)")
        return 0 if MARKER in s else 1
    if MARKER in s:
        print("already patched")
        return 0
    if s.count(ANCHOR) != 1:
        print("FAIL: anchor not found exactly once")
        return 1
    s = s.replace(ANCHOR, ANCHOR + BLOCK, 1)
    io.open(P, "w", encoding="utf-8", errors="surrogateescape").write(s)
    print("pe_init.c: printf() neutralized (kprintf untouched)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
