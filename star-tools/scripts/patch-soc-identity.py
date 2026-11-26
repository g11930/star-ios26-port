#!/usr/bin/env python3
"""P40: stop the K90 kernel from claiming this phone is an SM8750.

Scope: identity and log honesty only. No register value, no hardware access path,
no boot-arg TUNABLE and no new global variable is introduced. P34 died with
"kalloc_type_view() from kext() hasn't been rebuilt" after a TUNABLE moved the
__KLDDATA.__const / __kalloc_type layout, so this patch deliberately keeps the
KLD section layout as close to P38's kernel as possible: string literals plus one
local block containing a MIDR read and two printf calls.

The real silicon is identified from MIDR_EL1 PartNum:
  0xd05 / 0xd41 / 0xd44 = Cortex-A55 / A78 / X1 = SM8350 "star",
  Snapdragon 888, Xiaomi 11 Ultra, Adreno 660 (A6XX).
The adreno8 driver is a register map for the K90's SM8750 / Adreno 830 (A8XX)
and cannot drive an A6XX GPU, so on that silicon it says so and stays read-only.

Usage (inside WSL):
  python3 patch-soc-identity.py            # apply, with .p39 backups
  python3 patch-soc-identity.py --revert   # restore the backups
  python3 patch-soc-identity.py --check    # report current state, change nothing
"""
import os, shutil, sys, hashlib

KB = "/root/star26/kbuild/xnu-12377.121.6/bsd/dev"      # the tree that is actually built
REF = "/root/star26/hackios-xnu-kernel/xnu/files/bsd/dev"  # reference tree, kept in sync

OLD_ADRENO = '''	printf("adreno8: the Adreno 830 of SM8750, step by step: up to step %u of %u asked for%s%s (only, skip, pause, fine, watch, keep, speed, gmuclk, return all hang off the same name)\\n",
	    asked, count, only != 0 ? " -- but only one step will run" : "", adreno8_gpu8_keep ? " -- and everything stays up" : "");
'''

NEW_ADRENO = '''	/* The register map below is the K90's SM8750 / Adreno 830 (A8XX). Name the
	 * silicon actually running instead of assuming it: SM8350's ARMv8.2 parts are
	 * 0xd05/0xd41/0xd44 and its GPU is an Adreno 660 (A6XX), which this driver
	 * cannot drive. Nothing here changes what the steps do. */
	{
		uint64_t midr = __builtin_arm_rsr64("MIDR_EL1");
		unsigned part = (unsigned)((midr >> 4) & 0xfff);
		int is_sm8350 = part == 0xd05 || part == 0xd41 || part == 0xd44;
		printf("star: SoC identity MIDR_EL1 0x%016llx part 0x%03x: %s / %s\\n",
		    (unsigned long long)midr, part,
		    is_sm8350 ? "SM8350 'star' Snapdragon 888 (Xiaomi 11 Ultra)" : "unknown, not SM8750",
		    is_sm8350 ? "Adreno 660 A6XX - unsupported by this A8XX driver" : "GPU unknown");
		if (is_sm8350) {
			printf("adreno8: this SoC is NOT SM8750: GPU bring-up disabled, no register writes attempted\\n");
		}
	}
	printf("adreno8: A8XX driver written for K90 SM8750 / Adreno 830, steps up to %u of %u asked for%s%s (only, skip, pause, fine, watch, keep, speed, gmuclk, return all hang off the same name)\\n",
	    asked, count, only != 0 ? " -- but only one step will run" : "", adreno8_gpu8_keep ? " -- and everything stays up" : "");
'''

REPL = [
    ("adreno8/adreno8.c", OLD_ADRENO, NEW_ADRENO),
    ("annibale/annibale_iris.c",
     'iris_say("registering SM8750 Iris VPU v3.5 (/dev/annibale-iris)...\\n");',
     'iris_say("registering Iris VPU (K90 SM8750 profile; unsupported on this SoC) (/dev/annibale-iris)...\\n");'),
    ("annibale/annibale_iris_hw.c",
     'iris_say("SM8750 Iris VPU v3.5 online (HFI Gen2 ready)\\n");',
     'iris_say("Iris VPU v3.5 (K90 SM8750 profile) idle: not supported on this SoC\\n");'),
    ("annibale/annibale_modem.c",
     '"SM8750 MPSS modem state (0=off..6=data_connected)"',
     '"K90 SM8750 MPSS modem profile (unsupported on this SoC; 0=off..6=data_connected)"'),
    ("annibale/annibale_adsp.c",
     'say("SM8750 LPASS ADSP already running in SMEM (SMP2P slave-kernel READY)\\n");',
     'say("LPASS ADSP (K90 SM8750 profile) reports READY in SMEM; not used on this SoC\\n");'),
    ("annibale/annibale_adsp.c",
     'say("SM8750 LPASS ADSP authenticated and READY in %u ms\\n", ms);',
     'say("LPASS ADSP (K90 SM8750 profile) authenticated and READY in %u ms; not used on this SoC\\n", ms);'),
]


def md5(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()[:12]


def run(root, mode):
    print("== %s ==" % root)
    for rel, old, new in REPL:
        p = os.path.join(root, rel)
        bak = p + ".p39"
        if not os.path.exists(p):
            print("  SKIP (absent) %s" % rel)
            continue
        text = open(p).read()
        if mode == "check":
            state = "patched" if new in text else ("original" if old in text else "UNKNOWN")
            print("  %-34s %-9s %s" % (rel, state, md5(p)))
            continue
        if mode == "revert":
            if not os.path.exists(bak):
                print("  SKIP (no backup) %s" % rel)
                continue
            shutil.copy(bak, p)
            print("  reverted %-34s %s" % (rel, md5(p)))
            continue
        if new in text:
            print("  already patched %-28s %s" % (rel, md5(p)))
            continue
        n = text.count(old)
        if n != 1:
            print("  FAIL %s: expected exactly one match, found %d" % (rel, n))
            sys.exit(2)
        if not os.path.exists(bak):
            shutil.copy(p, bak)
        open(p, "w").write(text.replace(old, new, 1))
        print("  patched %-32s %s -> %s" % (rel, md5(bak), md5(p)))


if __name__ == "__main__":
    mode = "apply"
    if "--revert" in sys.argv:
        mode = "revert"
    elif "--check" in sys.argv:
        mode = "check"
    run(KB, mode)
    if os.path.isdir(REF):
        run(REF, mode)
    if mode == "apply":
        print("== verify: no self-identifying SM8750 strings left in printed messages ==")
        for rel, _, _ in REPL:
            p = os.path.join(KB, rel)
            t = open(p).read()
            for needle in ('"SM8750 ', 'the Adreno 830 of SM8750'):
                if needle in t:
                    print("  WARN %s still contains %r" % (rel, needle))
        print("done")
