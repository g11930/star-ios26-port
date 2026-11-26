#!/usr/bin/env python3
"""stage 12: the last three checkpoints -- around the exec of init/launchd.

Checkpoint 12 is reached, so the root volume mounted (vfs_mountroot succeeded) and
the crash is in the tail of bsd_init / bsdinit_task.  That tail ends in
load_init_program(p), which is where this port historically died
("EXECDBG: load_machfile -> 4 for /sbin/launchd", 4 = LOAD_FAILURE).

  13  bsdinit_task: after process_name("init")
  14  just before load_init_program()
  15  just after  load_init_program()   (never reached if the exec is the wall)
"""
import io
import sys

P = "/root/star26/star-native/bsd/kern/bsd_init.c"

EDITS = [
    ("cp13",
     '\tprocess_name("init", p);\n',
     '\tprocess_name("init", p);\n\tloader_checkpoint(13);\n'),
    ("cp14",
     '\tstar_display_milestone("launchd");\n\tload_init_program(p);\n',
     '\tstar_display_milestone("launchd");\n\tloader_checkpoint(14);\n\tload_init_program(p);\n\tloader_checkpoint(15);\n'),
]


def main():
    s = io.open(P, encoding="utf-8").read()
    if "loader_checkpoint(14)" in s:
        print("already patched")
        return 0
    for name, old, new in EDITS:
        n = s.count(old)
        if n != 1:
            print("FAILED %s: %d matches" % (name, n))
            return 1
        s = s.replace(old, new, 1)
        print("  %s" % name)
    io.open(P, "w", encoding="utf-8").write(s)
    out = io.open(P, encoding="utf-8").read()
    print("checkpoints:", sorted(int(x) for x in
          __import__("re").findall(r"loader_checkpoint\((\d+)\)", out)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
