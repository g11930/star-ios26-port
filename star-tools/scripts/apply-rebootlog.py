#!/usr/bin/env python3
"""
s84: log the reboot syscall's initiator (pid/comm/opt/message) at the
reboot_kernel entry, so the t=236s clean reboot's trigger is named
(suspect: the SpringBoard boot watchdog).
Boot-arg star_rebootlog=1 (default on), read-only, idempotent, backup,
strict anchors.  Usage: python3 apply-rebootlog.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/bsd/kern/kern_xxx.c"
CHECK = "--check" in sys.argv

OLD = '''		error = reboot_kernel(uap->opt, message);'''
NEW = '''		/* s84: name whoever calls the reboot (the t=236s clean restart
		 * on s83 had no panic -- suspect the SpringBoard boot watchdog). */
		{
			extern void loader_log_line(const char *format, ...)
			    __attribute__((format(printf, 1, 2)));
			static int enabled = -1;
			if (__improbable(enabled < 0)) {
				uint32_t v = 1;
				(void) PE_parse_boot_argn("star_rebootlog",
				    &v, sizeof(v));
				enabled = v ? 1 : 0;
			}
			if (enabled) {
				char note[192];
				snprintf(note, sizeof(note),
				    "\\nStarRebootLog: pid %d comm %s opt 0x%x msg '%s'\\n",
				    p->p_pid, p->p_comm, uap->opt,
				    message ? message : "");
				loader_log_line(note);
			}
		}
		error = reboot_kernel(uap->opt, message);'''

def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "StarRebootLog" in data:
        print("[skip] already applied")
        return
    cnt = data.count(OLD)
    if cnt != 1:
        print(f"[FAIL] anchor count={cnt} (need 1)")
        sys.exit(2)
    if CHECK:
        print("[check OK]")
        return
    bak = K + ".s84.bak"
    if not os.path.exists(bak):
        shutil.copy2(K, bak)
        print(f"[backup] {bak}")
    data = data.replace(OLD, NEW, 1)
    with open(K, "w", encoding="utf-8") as f:
        f.write(data)
    print("[patched] kern_xxx.c")


if __name__ == "__main__":
    main()
