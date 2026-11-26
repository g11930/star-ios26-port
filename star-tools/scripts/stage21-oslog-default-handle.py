#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
stage21 -- os_log_create() must not return NULL when oslog is disabled.

s25 (pthread kext restored) got past pthread_init() and panicked at
tcp_subr.c:738: `MPKL_CREATE_LOGOBJECT("com.apple.xnu.tcp")` is just
os_log_create(), and tcp_init() panics when it returns NULL.  stage19 made
os_log_create_impl() return OS_LOG_DISABLED (== NULL) because oslog is off.

Returning OS_LOG_DEFAULT (&_os_log_default) instead keeps every caller's
non-NULL expectation satisfied.  No log is actually emitted: os_log_disabled()
is still true, so os_log_encoded_* return early, and log_payload_send() still
bails out while kernel_firehose_addr == 0.  kprintf()/the loader ring remain
the real bring-up channel.

Idempotent; --check read-only.
"""
import io
import sys

P = "/root/star26/star-native/libkern/os/log.c"

OLD = """os_log_create_impl(const char *subsystem, const char *category, uint64_t stamp)
{
	if (os_log_disabled()) {
		return OS_LOG_DISABLED;
	}
"""

NEW = """os_log_create_impl(const char *subsystem, const char *category, uint64_t stamp)
{
	if (os_log_disabled()) {
		/*
		 * star-native: oslog is off because the firehose buffer is never
		 * allocated, but callers such as tcp_init() panic on a NULL log
		 * object.  Hand back the default (non-NULL) handle; no log is
		 * emitted (os_log_encoded_* return early, log_payload_send() bails).
		 */
		return OS_LOG_DEFAULT;
	}
"""

MARKER = "star-native: oslog is off because the firehose buffer"


def main():
    s = io.open(P, encoding="utf-8", errors="surrogateescape").read()
    if "--check" in sys.argv:
        ok = MARKER in s
        print("CHECK", "PASS" if ok else "FAIL")
        return 0 if ok else 1
    if MARKER in s:
        print("already patched")
        return 0
    if s.count(OLD) != 1:
        print("FAIL: os_log_create_impl anchor not found exactly once")
        return 1
    io.open(P, "w", encoding="utf-8", errors="surrogateescape").write(s.replace(OLD, NEW, 1))
    print("libkern/os/log.c: disabled os_log_create() now returns OS_LOG_DEFAULT")
    return 0


if __name__ == "__main__":
    sys.exit(main())
