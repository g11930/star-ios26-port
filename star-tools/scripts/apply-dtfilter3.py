#!/usr/bin/env python3
"""s81c: skip the OS_ACTIVITY_DT_MODE entry of the kernel's applog env
injection when star_dt_filter=1 (keeps the stderr entries so bbd/SB keep
logging to the console, but never open the logd streaming connection)."""
import os
import shutil
import sys

K = "/root/star26/star-native/bsd/kern/kern_exec.c"
CHECK = "--check" in sys.argv

OLD = '''	for (unsigned i = 0; exec_applog_oslog(imgp) && i < sizeof(applog_env) / sizeof(applog_env[0]); i++) {
		error = exec_add_user_string(imgp, CAST_USER_ADDR_T(applog_env[i]), UIO_SYSSPACE, TRUE);'''
NEW = '''	for (unsigned i = 0; exec_applog_oslog(imgp) && i < sizeof(applog_env) / sizeof(applog_env[0]); i++) {
		if (__improbable(star_dt_filter) && i == 0) {
			/* s81c: OS_ACTIVITY_DT_MODE opens the logd streaming
			 * connection; with logd dead (firehose version
			 * mismatch) the sync send parks the main thread on
			 * logd's full service port forever = the 98% stall.
			 * Keep ACTIVITY_LOG_STDERR/CFLOG_FORCE_STDERR so the
			 * console logging survives. */
			continue;
		}
		error = exec_add_user_string(imgp, CAST_USER_ADDR_T(applog_env[i]), UIO_SYSSPACE, TRUE);'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "s81c: OS_ACTIVITY_DT_MODE opens" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s81.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] kern_exec.c applog_env")


if __name__ == "__main__":
    main()
