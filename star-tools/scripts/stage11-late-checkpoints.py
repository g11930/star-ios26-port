#!/usr/bin/env python3
"""stage 11: three more checkpoints further down bsd_init.

Stage 10's nine points are all reached:
  1 arm_vm_init, 2/3 kalloc_init in/out, 4 GenericARMPE::start, 5/6 around the
  stage-7 display services, 7 bsd_init, 8/9 around annibale_ufs_init.

So everything the port touches is fine and the kernel dies *after*
star_display_handoff(), i.e. deeper in bsd_init.  (USB is not "dead" during a run:
the loader simply does not answer while the kernel executes; at a checkpoint it
returns and answers again.  That is why every earlier capture looked like an
instant hang.)

  10  after the DEVFS provider block (touch/audio/apfs probe started)
  11  just before vfs_mountroot()
  12  after a successful vfs_mountroot(), at the post hook
  13  just before bsd_init_launchd / exec of init
"""
import io
import sys

P = "/root/star26/star-native/bsd/kern/bsd_init.c"

EDITS = [
    ("cp10",
     "\t}\n#endif /* DEVFS */\n",
     "\t\tloader_checkpoint(10);\n\t}\n#endif /* DEVFS */\n"),
    ("cp11",
     '\t\tbsd_init_kprintf("vfs_mountroot\\n");\n',
     '\t\tloader_checkpoint(11);\n\t\tbsd_init_kprintf("vfs_mountroot\\n");\n'),
    ("cp12",
     '\tbsd_init_kprintf("calling mountroot_post_hook\\n");\n',
     '\tloader_checkpoint(12);\n\tbsd_init_kprintf("calling mountroot_post_hook\\n");\n'),
]


def main():
    s = io.open(P, encoding="utf-8").read()
    if "loader_checkpoint(12)" in s:
        print("already patched")
        return 0
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print("FAILED %s: %d matches" % (name, n))
            return 1
        s = s.replace(old, new, 1)
        print("  %s" % name)
    # 13: before the last call in bsd_init
    io.open(P, "w", encoding="utf-8").write(s)
    out = io.open(P, encoding="utf-8").read()
    for i, l in enumerate(out.split("\n"), 1):
        if "loader_checkpoint(" in l and "extern" not in l:
            print("%5d %s" % (i, l.strip()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
