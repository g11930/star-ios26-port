#!/usr/bin/env python3
"""s81b: the var patch inserted the shared token before the loop patch
could run; apply the loop (the actual OS_ACTIVITY_DT_MODE filter) now.
"""
import os
import shutil
import sys

K = "/root/star26/star-native/bsd/kern/kern_exec.c"
CHECK = "--check" in sys.argv

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

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "OS_ACTIVITY_DT_MODE=" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD_LOOP)
    if cnt != 1:
        print(f"[FAIL] loop: anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s81.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD_LOOP, NEW_LOOP, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] kern_exec.c loop")


if __name__ == "__main__":
    main()
