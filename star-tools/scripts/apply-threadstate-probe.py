#!/usr/bin/env python3
"""
s72: kernel-side per-thread state snapshot (HANDOFF §6 首选 "修探针").

Problems fixed:
1. TH_RUN threads were invisible (wait_regs skipped non-waiters), and the
   total thread count of launchd was never printed.
2. s70 register reads (machine_thread_get_state) returned garbage for
   launchd (x1=0xffffffffffffffff, rcv=0xd5a00000000); the kernel fields
   (state / wait_event / wait_result / waitq / zone) are the trustworthy
   record, read under thread_mtx.
3. s70 zid=65534 was mislabeled a "dynamic zone": it is ZONE_ID_INVALID
   (-2 on the uint16_t zone_id_t, zalloc.h:1666) = waitq not zone-backed =
   one of the static global_waitqs[] = a bare-event sleep, NOT an IPC wait.

osfmk half gains star_msgprobe_thread_diag(); bsd half prints one
kernel-state line for EVERY thread (with nthreads= in the header), tags
GLOBAL-WQ waits, and keeps the existing turnstile deep-dive for TH_WAIT
threads.  Read-only, log-only, idempotent, backed up, strict anchors.
Usage: python3 apply-threadstate-probe.py [--check]
"""
import os
import shutil
import sys

K = "/root/star26/star-native/osfmk/kern/star_msgprobe_k.c"
B = "/root/star26/star-native/bsd/dev/star/star_msgprobe.c"
CHECK = "--check" in sys.argv

K_TAIL = '''\tipc_object_unlock(io);
\treturn 0;
}'''

K_FUNC = '''

/*
 * s72: kernel-side per-thread state snapshot.  The s70 register reads
 * (machine_thread_get_state) returned garbage for launchd (x1=0xffff...,
 * rcv=0xd5a00000000), so the honest answer comes from the kernel fields
 * themselves, read under thread_mtx:
 *
 *   out[0] = th->state (raw TH_* bits: 1=WAIT 2=SUSP 4=RUN 8=UNINT)
 *   out[1] = th->wait_event (64-bit event last asserted)
 *   out[2] = th->wait_result
 *   out[3] = raw waitq address (0 = none)
 *   out[4] = zone id backing the waitq; ZONE_ID_INVALID (-2 on the 16-bit
 *            zone_id_t = 65534) means NOT zone-backed: one of the static
 *            global_waitqs[] -- a bare-event sleep, not an IPC wait.
 *   out[5] = th->suspend_count
 *
 * Returns 0, or -1 for a NULL thread.
 */
int
star_msgprobe_thread_diag(void *vth, uint64_t *out)
{
\tthread_t th = (thread_t)vth;
\twaitq_t wqlocal;

\tif (th == NULL) {
\t\treturn -1;
\t}
\tthread_mtx_lock(th);
\tout[0] = (uint64_t)th->state;
\tout[1] = (uint64_t)th->wait_event;
\tout[2] = (uint64_t)th->wait_result;
\twqlocal = th->waitq;
\tout[5] = (uint64_t)(int)th->suspend_count;
\tthread_mtx_unlock(th);

\tout[3] = (uint64_t)(unsigned long)wqlocal.wq_q;
\tif (wqlocal.wq_q == NULL) {
\t\tout[4] = ~0ull;
\t} else {
\t\tout[4] = (uint64_t)zone_id_for_element(wqlocal.wq_q,
\t\t    sizeof(struct waitq));
\t}
\treturn 0;
}'''

B_EXTERN_OLD = '''extern int star_msgprobe_turnstile_owner(void *thread,
\tstruct star_msgprobe_peer *out);'''
B_EXTERN_NEW = B_EXTERN_OLD + '''
extern int star_msgprobe_thread_diag(void *thread, uint64_t *out);'''

B_HEADER_OLD = '''\t\tIOLog("StarMsgProbe: === %s ===", found[i].comm);
\t\tn = star_msgprobe_task_threads(found[i].task, thr,
\t\t    STAR_MSGPROBE_MAXTHREADS);'''
B_HEADER_NEW = '''\t\tn = star_msgprobe_task_threads(found[i].task, thr,
\t\t    STAR_MSGPROBE_MAXTHREADS);
\t\tIOLog("StarMsgProbe: === %s === nthreads=%d", found[i].comm, n);'''

B_LOOP_OLD = '''\t\t\tuint64_t regs[5];
\t\t\tuint64_t x1, x4;

\t\t\tif (star_msgprobe_wait_regs(thr[t], regs) != 0) {
\t\t\t\tcontinue;
\t\t\t}
\t\t\tx1 = regs[1];
\t\t\tx4 = regs[2];'''

B_LOOP_NEW = '''\t\t\tuint64_t dg[6];
\t\t\tuint64_t regs[5];
\t\t\tuint64_t x1, x4;

\t\t\t/* s72: kernel-side state line for EVERY thread -- TH_RUN
\t\t\t * threads were invisible before (wait_regs skipped
\t\t\t * non-waiters), and launchd's saved user registers were
\t\t\t * garbage, so this line is the trustworthy record. */
\t\t\tif (star_msgprobe_thread_diag(thr[t], dg) != 0) {
\t\t\t\tcontinue;
\t\t\t}
\t\t\tIOLog("StarMsgProbe:   T#%d st=%llx we=%llx wr=%lu "
\t\t\t    "wq=%p zid=%lu susp=%lu",
\t\t\t    t, (unsigned long long)dg[0],
\t\t\t    (unsigned long long)dg[1],
\t\t\t    (unsigned long)dg[2],
\t\t\t    (void *)(unsigned long)dg[3],
\t\t\t    (unsigned long)dg[4],
\t\t\t    (unsigned long)dg[5]);
\t\t\tif (dg[3] != 0 && dg[4] == 65534ul) {
\t\t\t\tIOLog("StarMsgProbe:     -> GLOBAL-WQ "
\t\t\t\t    "(bare-event sleep, no IPC object)");
\t\t\t}
\t\t\tif (!(dg[0] & TH_WAIT)) {
\t\t\t\tprinted++;
\t\t\t\tcontinue;
\t\t\t}
\t\t\tif (star_msgprobe_wait_regs(thr[t], regs) != 0) {
\t\t\t\tregs[3] = 0;
\t\t\t\tregs[4] = 0;
\t\t\t}
\t\t\tx1 = regs[1];
\t\t\tx4 = regs[2];'''

PATCHES = [
    (K, "k-append", K_TAIL, K_TAIL + K_FUNC),
    (B, "b-extern", B_EXTERN_OLD, B_EXTERN_NEW),
    (B, "b-header", B_HEADER_OLD, B_HEADER_NEW),
    (B, "b-loop",   B_LOOP_OLD,    B_LOOP_NEW),
]

SKIP_TOKEN = {
    "k-append": "star_msgprobe_thread_diag",
    "b-extern": "star_msgprobe_thread_diag",
    "b-header": "nthreads=",
    "b-loop":   "T#%d",
}


def main():
    print(f"mode={'CHECK' if CHECK else 'APPLY'}")
    for path, label, old, new in PATCHES:
        with open(path, "r", encoding="utf-8") as f:
            data = f.read()
        if SKIP_TOKEN[label] in data:
            print(f"[skip] {label}: already applied")
            continue
        cnt = data.count(old)
        if cnt != 1:
            print(f"[FAIL] {label}: anchor count={cnt} (need 1)")
            sys.exit(2)
        if CHECK:
            print(f"[check OK] {label}")
            continue
        bak = path + ".s72.bak"
        if not os.path.exists(bak):
            shutil.copy2(path, bak)
            print(f"[backup] {bak}")
        data = data.replace(old, new, 1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(data)
        print(f"[patched] {label}")
    print("done")


if __name__ == "__main__":
    main()
