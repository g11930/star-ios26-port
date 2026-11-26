#!/usr/bin/env python3
"""
s87: inject the Metal registration library into SpringBoard and
backboardd (the K90 production inject line, package.py:165).

Why: the rendering path needs IOSurface compression preferences set before
QuartzCore picks a surface format (the stub GPU driver imports linear
surfaces only).  That is done by libannibale-sbmetal-experiment.dylib's
registration sequence -- the K90 ships it in etc/inject.conf for
"SpringBoard backboardd"; our inject list lacks the line.

Boot-arg star_sbmetal=1.  Read-only, idempotent, backup, strict anchors.
Usage: python3 apply-sbmetal-inject.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/bsd/kern/kern_exec.c"
CHECK = "--check" in sys.argv

OLD_VAR = "static char exec_inject_conf[4096];"
NEW_VAR = '''static char exec_inject_conf[4096];
static int star_sbmetal_enabled = -1;'''

OLD_RET = '''		}
	}
	return any;
}

__attribute__((noinline))
static int
exec_extract_strings(struct image_params *imgp)'''
NEW_RET = '''		}
	}

	/* s87: the Metal registration sequence's library for SpringBoard and
	 * backboardd (the K90 production inject line).  It sets the IOSurface
	 * compression preference and registers the Metal device before
	 * QuartzCore picks a format -- without it nothing reaches the
	 * framebuffer.  Gated by star_sbmetal=1. */
	if (__improbable(star_sbmetal_enabled < 0)) {
		uint32_t v = 1;
		(void) PE_parse_boot_argn("star_sbmetal", &v, sizeof(v));
		star_sbmetal_enabled = v ? 1 : 0;
	}
	if (star_sbmetal && used + 1 + 50 < size &&
	    ((namelen == 11 && strncmp(name, "SpringBoard", 11) == 0) ||
	    (namelen == 10 && strncmp(name, "backboardd", 10) == 0))) {
		static const char exp[] =
		    "/annibale/lib/libannibale-sbmetal-experiment.dylib";
		if (any) {
			env[used++] = ':';
		}
		memcpy(env + used, exp, sizeof(exp) - 1);
		used += sizeof(exp) - 1;
		env[used] = 0;
		any = true;
	}
	return any;
}

__attribute__((noinline))
static int
exec_extract_strings(struct image_params *imgp)'''

PATCHES = [
    ("var", OLD_VAR, NEW_VAR),
    ("ret", OLD_RET, NEW_RET),
]


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    with open(K, "r", encoding="utf-8") as f:
        data = f.read()
    if "s87: the Metal registration sequence" in data:
        print("[skip] already applied")
        return
    changed = False
    for label, old, new in PATCHES:
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
        bak = K + ".s87.bak"
        if not os.path.exists(bak):
            shutil.copy2(K, bak)
            print(f"[backup] {bak}")
        with open(K, "w", encoding="utf-8") as f:
            f.write(data)
        print("[patched] kern_exec.c")
    print("done")


if __name__ == "__main__":
    main()
