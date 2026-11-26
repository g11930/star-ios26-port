#!/usr/bin/env python3
"""P28 fix-up: struct proc is opaque in osfmk, so take the pid from task_pid() instead.

The first attempt used cp->p_pid / cp->p_comm, which sleh.c cannot see (no
bsd/sys/proc_internal.h, and pulling it into osfmk/arm64 has no precedent).  task_pid() is
declared in kern/task.h, which sleh.c already includes, and the pid is enough: the EXECDBG
lines in the same log already name every process.
"""
import sys

SLEH = "/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c"

OLD = (
    "\t{\n"
    "\t\tproc_t cp = current_proc();\n"
    "\t\tkprintf(\"P28FAULT: pid %d %s addr %llx pc %llx lr %llx esr %llx\\n\",\n"
    "\t\t    cp->p_pid, cp->p_comm,\n"
    "\t\t    (unsigned long long)fault_addr,\n"
    "\t\t    (unsigned long long)get_saved_state_pc(state),\n"
    "\t\t    (unsigned long long)get_saved_state_lr(state),\n"
    "\t\t    (unsigned long long)esr);\n"
    "\t}\n"
)

NEW = (
    "\t{\n"
    "\t\tkprintf(\"P28FAULT: pid %d addr %llx pc %llx lr %llx esr %llx\\n\",\n"
    "\t\t    task_pid(current_task()),\n"
    "\t\t    (unsigned long long)fault_addr,\n"
    "\t\t    (unsigned long long)get_saved_state_pc(state),\n"
    "\t\t    (unsigned long long)get_saved_state_lr(state),\n"
    "\t\t    (unsigned long long)esr);\n"
    "\t}\n"
)

with open(SLEH, "r", encoding="utf-8") as f:
    text = f.read()

if NEW in text:
    print("already fixed")
    sys.exit(0)

n = text.count(OLD)
if n != 1:
    sys.exit("old block found %d times" % n)

with open(SLEH, "w", encoding="utf-8") as f:
    f.write(text.replace(OLD, NEW))
print("fixed")
