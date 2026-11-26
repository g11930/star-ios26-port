#!/usr/bin/env python3
"""P32: a watchdog inside SpringBoard that says where its threads are.

SpringBoard never builds a render pipeline on star: it gets through the library's start-up,
answers Metal, and then does nothing for minutes while the panel keeps the Apple logo. The
library already prints a process's threads when one of its draws runs long, but that only
happens in backboardd, and only once something has been drawn. So this adds the same dump to
libannibale-sb26.dylib, on a thread of its own: the main queue can be blocked for minutes by a
single draw on a software rasteriser, so a dispatch_after would never fire.

Each line names the module and offset of every frame, which is what turns "SpringBoard is stuck"
into "SpringBoard is asleep in this call".
"""
import re
import sys

SRC = "/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c"

INCLUDES_ANCHOR = "#include <os/lock.h>\n"
INCLUDES_ADD = """#include <mach/mach.h>
#include <mach/thread_act.h>
#include <pthread.h>
"""

FUNCS = r'''
/*
 * Where a thread of this process is, as module and offset. The first line of a pair is the
 * registers, the second the return addresses from the frame chain; `binds` in the metal library
 * prints the same thing for backboardd, and this is that dump for SpringBoard.
 */
static int
sb26_where(char *out, size_t size, uintptr_t address)
{
    Dl_info where;
    int n;

    if (address != 0 && dladdr((void *)address, &where) != 0 && where.dli_fname != NULL) {
        const char *name = strrchr(where.dli_fname, '/');

        n = snprintf(out, size, " %s+0x%lx", name != NULL ? name + 1 : where.dli_fname,
            (unsigned long)(address - (uintptr_t)where.dli_fbase));
    } else {
        n = snprintf(out, size, " %p", (void *)address);
    }
    return n < 0 ? 0 : n >= (int)size ? (int)size - 1 : n;
}

static void
sb26_dump_threads(unsigned when)
{
    thread_act_array_t threads = NULL;
    mach_msg_type_number_t count = 0;

    if (task_threads(mach_task_self(), &threads, &count) != KERN_SUCCESS) {
        fprintf(stderr, "sb26: watchdog %u: cannot list this process's threads\n", when);
        return;
    }
    fprintf(stderr, "sb26: watchdog %u: %u threads\n", when, (unsigned)count);
    for (mach_msg_type_number_t i = 0; i < count; i++) {
        arm_thread_state64_t state;
        mach_msg_type_number_t state_count = ARM_THREAD_STATE64_COUNT;
        thread_identifier_info_data_t ident;
        mach_msg_type_number_t ident_count = THREAD_IDENTIFIER_INFO_COUNT;
        uintptr_t pc = 0, lr = 0, fp = 0, sp = 0;
        const char *image = "?";
        unsigned long long tid = 0;
        char frames[768];
        int used = 0;

        frames[0] = '\0';
        if (thread_get_state(threads[i], ARM_THREAD_STATE64, (thread_state_t)&state,
                &state_count) == KERN_SUCCESS) {
            Dl_info where;
            pthread_t posix = pthread_from_mach_thread_np(threads[i]);
            uintptr_t top = posix != NULL ? (uintptr_t)pthread_get_stackaddr_np(posix) : 0;
            uintptr_t bottom = posix != NULL ? top - pthread_get_stacksize_np(posix) : 0;

            pc = (uintptr_t)__darwin_arm_thread_state64_get_pc(state);
            lr = (uintptr_t)__darwin_arm_thread_state64_get_lr(state);
            fp = (uintptr_t)__darwin_arm_thread_state64_get_fp(state);
            sp = (uintptr_t)__darwin_arm_thread_state64_get_sp(state);
            if (pc != 0 && dladdr((void *)pc, &where) != 0 && where.dli_fname != NULL)
                image = where.dli_fname;
            used += sb26_where(frames + used, sizeof(frames) - (size_t)used, pc);
            used += sb26_where(frames + used, sizeof(frames) - (size_t)used, lr);
            for (uintptr_t at = fp, depth = 0; depth < 16 && (at & 7) == 0 && at >= bottom &&
                at + 16 <= top && used < (int)sizeof(frames) - 64; depth++) {
                uintptr_t next = ((const uintptr_t *)at)[0];
                uintptr_t back = (uintptr_t)ptrauth_strip(((void *const *)at)[1],
                    ptrauth_key_return_address);

                used += sb26_where(frames + used, sizeof(frames) - (size_t)used, back);
                if (next <= at)
                    break;
                at = next;
            }
        }
        if (thread_info(threads[i], THREAD_IDENTIFIER_INFO, (thread_info_t)&ident, &ident_count) ==
            KERN_SUCCESS)
            tid = (unsigned long long)ident.thread_id;
        fprintf(stderr, "sb26: stall pc %p lr %p fp %p sp %p (%s) tid %llu\n", (void *)pc, (void *)lr,
            (void *)fp, (void *)sp, image, tid);
        fprintf(stderr, "sb26: stall frames tid %llu:%s\n", tid, frames);
        mach_port_deallocate(mach_task_self(), threads[i]);
    }
    vm_deallocate(mach_task_self(), (vm_address_t)threads, count * sizeof(thread_t));
}

/* Its own thread, because the main queue is what a long draw blocks. The times are seconds after
 * the library started; the last one is past any run we would still be watching. */
static void *
sb26_watchdog(void *context)
{
    static const unsigned at[] = { 25, 55, 90, 130, 175, 225 };
    unsigned elapsed = 0;

    (void)context;
    for (size_t i = 0; i < sizeof(at) / sizeof(at[0]); i++) {
        while (elapsed < at[i]) {
            sleep(1);
            elapsed++;
        }
        sb26_dump_threads(at[i]);
    }
    return NULL;
}

static void
sb26_start_watchdog(void)
{
    pthread_t thread;

    if (pthread_create(&thread, NULL, sb26_watchdog, NULL) == 0)
        pthread_detach(thread);
    else
        fprintf(stderr, "sb26: watchdog: pthread_create failed\n");
}

'''

CALL_ANCHOR = "    install_unlock();\n"
CALL_ADD = "    install_unlock();\n    sb26_start_watchdog();\n"


def main():
    with open(SRC) as f:
        text = f.read()
    if "sb26_start_watchdog" in text:
        sys.exit("already patched")
    if INCLUDES_ANCHOR not in text:
        sys.exit("include anchor missing")
    text = text.replace(INCLUDES_ANCHOR, INCLUDES_ANCHOR + INCLUDES_ADD, 1)

    # put the watchdog right before install_unlock's definition
    defn = "static void\ninstall_unlock(void)\n"
    if defn not in text:
        sys.exit("install_unlock definition not found")
    text = text.replace(defn, FUNCS.lstrip("\n") + defn, 1)

    if CALL_ANCHOR not in text:
        sys.exit("call anchor not found")
    text = text.replace(CALL_ANCHOR, CALL_ADD, 1)

    with open(SRC, "w") as f:
        f.write(text)
    print("patched", SRC)


if __name__ == "__main__":
    main()
