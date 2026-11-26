#!/usr/bin/env python3
"""
s81 (fix C): drop OS_ACTIVITY_DT_MODE from every exec's environment when the
boot-arg star_dt_filter=1.

Why: OS_ACTIVITY_DT_MODE=1 (stage27) makes libtrace open the logd streaming
XPC connection; with logd dead (kernel firehose disabled since stage19 ->
"firehose libdispatch version mismatch (20180226)" -> brk #1 -> SIGTRAP x16),
the sync send parks backboardd/SpringBoard main threads on logd's full
service port forever = the 98% stall.  Dropping the variable per exec cuts
that connection off at the source while the kernel-side firehose fix (D) is
prepared.

Read-mostly (skips one env entry), boot-arg gated, idempotent, backup,
strict anchors.  Usage: python3 apply-dtfilter.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/bsd/kern/kern_exec.c"
CHECK = "--check" in sys.argv

OLD_VAR = "static char rwa_software_env[] = \"RWA_SOFTWARE=1\";"
NEW_VAR = '''static int     star_dt_filter = -1;
static char rwa_software_env[] = "RWA_SOFTWARE=1";'''

OLD_LOOP = '''		envv += ptr_size;
		if (env == 0LL) {
			break;
		}
		/*
		 * av[n...] = env[n]
		 */
		error = exec_add_user_string(imgp, env, imgp->ip_seg, TRUE);'''
NEW_LOOP = '''		envv += ptr_size;
		if (env == 0LL) {
			break;
		}
		/*
		 * av[n...] = env[n]
		 */
		if (__improbable(star_dt_filter < 0)) {
			uint32_t v = 1;
			(void) PE_parse_boot_argn("star_dt_filter", &v,
			    sizeof(v));
			star_dt_filter = v ? 1 : 0;
		}
		if (star_dt_filter) {
			/* s81: OS_ACTIVITY_DT_MODE opens the logd streaming
			 * connection; with logd dead the sync send parks the
			 * main thread on logd's full service port forever.
			 * Drop it here (the plist/env keeps it otherwise). */
			char peek[24];
			if (COPYIN(env, peek, sizeof(peek)) == 0 &&
			    strncmp(peek, "OS_ACTIVITY_DT_MODE=", 20) == 0) {
				continue;
			}
		}
		error = exec_add_user_string(imgp, env, imgp->ip_seg, TRUE);'''

PATCHES = [
    ("var",  OLD_VAR, NEW_VAR, "star_dt_filter"),
    ("loop", OLD_LOOP, NEW_LOOP, "star_dt_filter"),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    changed = False
    for label, old, new, token in PATCHES:
        if token in data:
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        data = data.replace(old, new, 1)
        changed = True
    if CHECK:
        print("done")
        return
    if changed:
        bak = K + ".s81.bak"
        if not os.path.exists(bak):
            shutil.copy2(K, bak)
            print(f"[backup] {bak}")
        with open(K, "w", encoding="utf-8") as f:
            f.write(data)
        print("[patched] kern_exec.c")
    print("done")


if __name__ == "__main__":
    main()
