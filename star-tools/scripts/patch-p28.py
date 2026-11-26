#!/usr/bin/env python3
"""P28: two diagnostic probes in the kernel, no behaviour change.

P27's log shows the shader side is finished (0 refusals, every pipeline builds), and that
backboardd completes its own init at 3:12:49.  What is left is that SpringBoard dies a
second or two after the sb26 injection finishes installing its hooks -- sixteen launches,
each followed by launchd's 10/20/40/80/160 s respawn backoff.  Nothing in the log says how
it died, so the kernel writes it down instead:

  1. handle_user_abort(): the last point before an unresolvable fault becomes a signal.
     Prints pid, name, fault address, pc, lr and esr.  Only fires for faults the VM could
     not resolve, so it is a handful of lines, not a page-fault stream.
  2. proc_exit(): pid, name, xstat and ppid, so a clean exit or a SIGKILL from the watchdog
     is distinguishable from a SIGSEGV/SIGBUS.
"""
import sys

TREE = "/root/star26/kbuild/xnu-12377.121.6"
SLEH = TREE + "/osfmk/arm64/sleh.c"
EXIT = TREE + "/bsd/kern/kern_exit.c"

FAULT_ANCHOR = (
    "\tcodes[1] = fault_addr;\n"
    "#if __has_feature(ptrauth_calls)\n"
    "\tbool is_data_abort = (ESR_EC(esr) == ESR_EC_DABORT_EL0);\n"
)

FAULT_INSERT = (
    "\t/* P28: the VM could not resolve this fault, so it is about to become a signal.\n"
    "\t * Write down who and where before that happens. */\n"
    "\t{\n"
    "\t\tproc_t cp = current_proc();\n"
    "\t\tkprintf(\"P28FAULT: pid %d %s addr %llx pc %llx lr %llx esr %llx\\n\",\n"
    "\t\t    cp->p_pid, cp->p_comm,\n"
    "\t\t    (unsigned long long)fault_addr,\n"
    "\t\t    (unsigned long long)get_saved_state_pc(state),\n"
    "\t\t    (unsigned long long)get_saved_state_lr(state),\n"
    "\t\t    (unsigned long long)esr);\n"
    "\t}\n\n" + FAULT_ANCHOR
)

EXIT_ANCHOR = "\tpid = proc_getpid(p);\n\texitval = p->p_xstat;\n"

EXIT_INSERT = EXIT_ANCHOR + (
    "\tif (pid > 1) {\n"
    "\t\tkprintf(\"P28EXIT: pid %d %s xstat %d ppid %d\\n\",\n"
    "\t\t    pid, p->p_comm, exitval, p->p_ppid);\n"
    "\t}\n"
)


def patch(path, anchor, replacement, marker):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    if marker in text:
        print("%s: already patched" % path)
        return
    n = text.count(anchor)
    if n != 1:
        sys.exit("%s: anchor found %d times, expected 1" % (path, n))
    text = text.replace(anchor, replacement)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("%s: patched" % path)


patch(SLEH, FAULT_ANCHOR, FAULT_INSERT, "P28FAULT")
patch(EXIT, EXIT_ANCHOR, EXIT_INSERT, "P28EXIT")
