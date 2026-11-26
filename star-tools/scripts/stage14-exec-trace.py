#!/usr/bin/env python3
"""stage 14: STARX trace lines across the exec -> launchd path.

Context.  Everything up to `bsd_init` -> process_name("init") is proven good by
checkpoint 7..13, and checkpoint 14 (immediately before load_init_program())
is reached.  So the wall is inside the exec of /sbin/launchd, and the checkpoints
cannot narrow it further without one flash per bit.

The old iOS16 evidence for this path was "EXECDBG: load_machfile -> 4 for
/sbin/launchd" (4 = LOAD_FAILURE).  Those EXECDBG lines are still in the tree but
they are `(printf)(...)` and CONFIG_NO_PRINTF_STRINGS makes printf a no-op that
also discards the format strings -- they have been silent for a while, which is
why nothing ever showed up in the logs for this path.

So: one run, ~21 trace lines, all through loader_log_line() (the ring the loader
polls live for its on-screen KERNEL BOOT CONSOLE card, and the same bytes that
end up in the logdump partition).  No control flow change, no checkpoints, no
IOLog (its implementation calls assertf on interrupts-enabled and is not even
linked in this build).

Trace tags, in the order they should appear on a healthy boot:
    LIP_ENTER      load_init_program entry                     a=map_page_size
    LIP_SCRATCH    mach_vm_allocate_kernel for argv scratch     a=scratch_addr
    LIP_TRY        each candidate path                          s=path a=index
    LIP_RET        load_init_program_at_path returned           s=path a=errno
    LIPA_ENTER     load_init_program_at_path entry              s=path
    LIPA_COPYOUT   copyout(program name)                        a=errno b=argv0
    LIPA_EXEC      just before execve()                         a=is64 b=argp
    LIPA_RET       execve() returned                            a=errno b=retval
    ME_ENTER       __mac_execve entry                           a=is64 b=fname
    ME_CLONE       cloneproc() returned                         a=ok
    EAI_ALLOC      execargs_alloc()                             a=errno
    EAI_NAMEI      namei()                                      a=errno
    EAI_PERM       exec_check_permissions()                     a=errno
    EAI_RDWR       vn_rdwr() of the first page                  a=errno b=resid
    EAI_IMGACT     imgact loop settled                          a=which b=errno
    EAI_EXIT       exec_activate_image() leaving                a=errno
    LM_ENTER       load_machfile entry                          a=arch_off b=size
    LM_PARSE       parse_machfile() returned                    a=lret
    AES_ENTRY      thread_setentrypoint() done                  a=entry_point
    ME_ACT         exec_activate_image() back in __mac_execve    a=errno
    ME_SWITCH      proc_exec_switch_task() done                 a=1
"""
import io
import sys

KX = "/root/star26/star-native/bsd/kern/kern_exec.c"
ML = "/root/star26/star-native/bsd/kern/mach_loader.c"

HELPER = r'''
/*
 * star_trace -- diagnostic lines into the loader's log ring.
 *
 * CONFIG_NO_PRINTF_STRINGS turns the printf family into no-ops that also drop
 * the format strings, and IOLog has no definition anywhere in this build (the
 * symbol lands undefined-weak), so both are silent.  The loader's ring is the
 * only channel that produces text: the loader polls it live for the on-screen
 * KERNEL BOOT CONSOLE card, and the same bytes are written to the logdump
 * partition.  Plain data, no control flow.
 */
extern void loader_log_line(const char *line);

void
star_trace(const char *tag, long long a, long long b)
{
	char line[128];

	snprintf(line, sizeof(line), "\nSTARX %s a=%lld b=%lld\n", tag, a, b);
	loader_log_line(line);
}

void
star_trace_s(const char *tag, const char *s, long long a)
{
	char line[192];

	snprintf(line, sizeof(line), "\nSTARX %s %s a=%lld\n", tag, s ? s : "(null)", a);
	loader_log_line(line);
}

'''

KX_EDITS = [
    ("helper def",
     "struct image_params;    /* Forward */\n",
     "struct image_params;    /* Forward */\n" + HELPER),

    # ---- load_init_program -------------------------------------------------
    ("LIP_ENTER / LIP_SCRATCH",
     "\tmach_vm_offset_t scratch_addr = 0;\n"
     "\tmach_vm_size_t map_page_size = vm_map_page_size(map);\n",
     "\tmach_vm_offset_t scratch_addr = 0;\n"
     "\tmach_vm_size_t map_page_size = vm_map_page_size(map);\n"
     "\n"
     "\tstar_trace(\"LIP_ENTER\", (long long)map_page_size, 0);\n"),

    ("LIP_SCRATCH",
     "\t(void) mach_vm_allocate_kernel(map, &scratch_addr, map_page_size,\n"
     "\t    VM_MAP_KERNEL_FLAGS_ANYWHERE());\n",
     "\t(void) mach_vm_allocate_kernel(map, &scratch_addr, map_page_size,\n"
     "\t    VM_MAP_KERNEL_FLAGS_ANYWHERE());\n"
     "\tstar_trace(\"LIP_SCRATCH\", (long long)scratch_addr, 0);\n"),

    ("LIP_TRY / LIP_RET",
     "\t\terror = load_init_program_at_path(p, (user_addr_t)scratch_addr, init_programs[i]);\n",
     "\t\tstar_trace_s(\"LIP_TRY\", init_programs[i], (long long)i);\n"
     "\t\terror = load_init_program_at_path(p, (user_addr_t)scratch_addr, init_programs[i]);\n"
     "\t\tstar_trace_s(\"LIP_RET\", init_programs[i], (long long)error);\n"),

    # ---- load_init_program_at_path ----------------------------------------
    ("LIPA_ENTER",
     "\t/*\n\t * Copy out program name.\n\t */\n"
     "\tsize_t path_length = strlen(path) + 1;\n",
     "\tstar_trace_s(\"LIPA_ENTER\", path, (long long)scratch_addr);\n"
     "\t/*\n\t * Copy out program name.\n\t */\n"
     "\tsize_t path_length = strlen(path) + 1;\n"),

    ("LIPA_COPYOUT",
     "\terror = copyout(path, argv0, path_length);\n",
     "\terror = copyout(path, argv0, path_length);\n"
     "\tstar_trace(\"LIPA_COPYOUT\", (long long)error, (long long)argv0);\n"),

    ("LIPA_EXEC / LIPA_RET",
     "\treturn execve(p, &init_exec_args, retval);\n",
     "\tstar_trace(\"LIPA_EXEC\", (long long)proc_is64bit(p), (long long)scratch_addr);\n"
     "\terror = execve(p, &init_exec_args, retval);\n"
     "\tstar_trace(\"LIPA_RET\", (long long)error, (long long)retval[0]);\n"
     "\treturn error;\n"),

    # ---- __mac_execve ------------------------------------------------------
    ("ME_ENTER",
     "\t\tgoto exit_with_error;\n\t}\n"
     "\timgp = &__execve_data->imgp;\n",
     "\t\tgoto exit_with_error;\n\t}\n"
     "\tstar_trace(\"ME_ENTER\", (long long)is_64, (long long)uap->fname);\n"
     "\timgp = &__execve_data->imgp;\n"),

    ("ME_ACT",
     "\terror = exec_activate_image(imgp);\n"
     "\t/* thread and task ref returned for vfexec case */\n",
     "\terror = exec_activate_image(imgp);\n"
     "\tstar_trace(\"ME_ACT\", (long long)error, 0);\n"
     "\t/* thread and task ref returned for vfexec case */\n"),

    ("ME_SWITCH",
     "\tif (!error) {\n"
     "\t\tp = proc_exec_switch_task(current_proc(), p, old_task, new_task, imgp, &inherit);\n"
     "\t\t/* proc ref returned */\n"
     "\t\tshould_release_proc_ref = TRUE;\n"
     "\t}\n"
     "\n"
     "\tkauth_cred_unref(&context.vc_ucred);\n",
     "\tif (!error) {\n"
     "\t\tp = proc_exec_switch_task(current_proc(), p, old_task, new_task, imgp, &inherit);\n"
     "\t\t/* proc ref returned */\n"
     "\t\tshould_release_proc_ref = TRUE;\n"
     "\t\tstar_trace(\"ME_SWITCH\", 1, 0);\n"
     "\t}\n"
     "\n"
     "\tkauth_cred_unref(&context.vc_ucred);\n"),

    # ---- exec_activate_image ----------------------------------------------
    ("EAI_ALLOC",
     "\terror = execargs_alloc(imgp);\n\tif (error) {\n\t\tgoto bad_notrans;\n\t}\n",
     "\terror = execargs_alloc(imgp);\n"
     "\tstar_trace(\"EAI_ALLOC\", (long long)error, 0);\n"
     "\tif (error) {\n\t\tgoto bad_notrans;\n\t}\n"),

    ("EAI_NAMEI",
     "again:\n\terror = namei(ndp);\n",
     "again:\n\terror = namei(ndp);\n"
     "\tstar_trace(\"EAI_NAMEI\", (long long)error, 0);\n"),

    ("EAI_PERM",
     "\terror = exec_check_permissions(imgp);\n",
     "\terror = exec_check_permissions(imgp);\n"
     "\tstar_trace(\"EAI_PERM\", (long long)error, 0);\n"),

    ("EAI_RDWR",
     "\t    &resid, vfs_context_proc(imgp->ip_vfs_context));\n",
     "\t    &resid, vfs_context_proc(imgp->ip_vfs_context));\n"
     "\tstar_trace(\"EAI_RDWR\", (long long)error, (long long)resid);\n"),

    ("EAI_IMGACT",
     "\tif (error == -1) {\n\t\terror = ENOEXEC;\n",
     "\tstar_trace(\"EAI_IMGACT\", (long long)i, (long long)error);\n"
     "\tif (error == -1) {\n\t\terror = ENOEXEC;\n"),

    ("EAI_EXIT",
     "bad_notrans:\n\tif (imgp->ip_strings) {\n",
     "bad_notrans:\n"
     "\tstar_trace(\"EAI_EXIT\", (long long)error, 0);\n"
     "\tif (imgp->ip_strings) {\n"),

    # ---- activate_exec_state ----------------------------------------------
    ("AES_ENTRY",
     "\tthread_setentrypoint(thread, result->entry_point);\n",
     "\tthread_setentrypoint(thread, result->entry_point);\n"
     "\tstar_trace(\"AES_ENTRY\", (long long)result->entry_point, 0);\n"),
]

ML_EDITS = [
    ("extern decl",
     "load_return_t\nload_machfile(\n",
     "extern void star_trace(const char *tag, long long a, long long b);\n"
     "\n"
     "load_return_t\nload_machfile(\n"),

    ("LM_ENTER",
     "\t\treturn LOAD_BADMACHO;\n\t}\n\n"
     "\tresult->is_64bit_addr = ((imgp->ip_flags & IMGPF_IS_64BIT_ADDR) == IMGPF_IS_64BIT_ADDR);\n",
     "\t\treturn LOAD_BADMACHO;\n\t}\n\n"
     "\tstar_trace(\"LM_ENTER\", (long long)file_offset, (long long)macho_size);\n"
     "\tresult->is_64bit_addr = ((imgp->ip_flags & IMGPF_IS_64BIT_ADDR) == IMGPF_IS_64BIT_ADDR);\n"),

    ("LM_PARSE",
     "\tif (lret != LOAD_SUCCESS) {\n\t\timgp->ip_free_map = map;\n\t\treturn lret;\n\t}\n",
     "\tstar_trace(\"LM_PARSE\", (long long)lret, 0);\n"
     "\tif (lret != LOAD_SUCCESS) {\n\t\timgp->ip_free_map = map;\n\t\treturn lret;\n\t}\n"),
]


def apply(path, edits):
    s = io.open(path, encoding="utf-8").read()
    for name, old, new in edits:
        n = s.count(old)
        if n != 1:
            print("FAILED %s: %d matches in %s" % (name, n, path))
            return None
        s = s.replace(old, new, 1)
        print("  %s" % name)
    io.open(path, "w", encoding="utf-8").write(s)
    return s


def main():
    probe = io.open(KX, encoding="utf-8").read()
    if "star_trace(" in probe:
        print("already patched")
        return 0
    if apply(KX, KX_EDITS) is None:
        return 1
    if apply(ML, ML_EDITS) is None:
        return 1
    out = io.open(KX, encoding="utf-8").read()
    print("trace tags:", out.count('star_trace'), "+", out.count('star_trace_s'))
    return 0


if __name__ == "__main__":
    sys.exit(main())
