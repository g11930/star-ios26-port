#!/usr/bin/env python3
"""Make annibale_goodix_init self-delay via a kernel thread, so it runs AFTER ignition.
Restore the call from annibale_input_init (touch_write-only never fires)."""
p='/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s=open(p,encoding='utf-8').read()

# 1) Add a delayed-entry thread wrapper before annibale_goodix_init
anchor='''static bool annibale_goodix_inited;   /* iOS26 input.c calls init twice; iOS16 called once */

void
annibale_goodix_init(void)
{
\tif (annibale_goodix_inited) return;
\tannibale_goodix_inited = true;

\tuint32_t enabled = 0;'''
new='''static bool annibale_goodix_inited;   /* iOS26 input.c calls init twice; iOS16 called once */
static void annibale_goodix_probe_now(void);

/* Boot-time init would contend with launchd's preboot/ignition on RPMh and trap the boot.
 * Enter from a thread that waits for userland to come up, then run the real probe. */
static void
annibale_goodix_delayed(void *parameter, wait_result_t result)
{
\t(void)parameter; (void)result;
\tdelay_for_interval(12, NSEC_PER_SEC);
\tannibale_goodix_probe_now();
}

void
annibale_goodix_init(void)
{
\tif (annibale_goodix_inited) return;
\tannibale_goodix_inited = true;

\tuint32_t enabled = 0;'''
if anchor not in s:
    print('ANCHOR MISS'); raise SystemExit(2)
s=s.replace(anchor,new,1)

# 2) Rename the real body to _now, and make annibale_goodix_init spawn the delayed thread.
# Currently annibale_goodix_init has the full body. We want:
#   annibale_goodix_init() -> check boot-arg, if touchscreen=1 spawn delayed thread
#   annibale_goodix_probe_now() -> the old body (thread start etc.)
# Simplest: add a separate entry used by input.c. Rename the function and add wrapper.
s=s.replace('''void
annibale_goodix_init(void)
{
\tif (annibale_goodix_inited) return;
\tannibale_goodix_inited = true;
''','''static void
annibale_goodix_probe_now(void)
{
''',1)
# Now append a new public wrapper at end of file that spawns the delayed thread exactly once.
wrapper='''
void
annibale_goodix_init(void)
{
\tuint32_t enabled = 0;
\tthread_t thread;

\tif (annibale_goodix_inited) return;
\tif (!PE_parse_boot_argn("touchscreen", &enabled, sizeof(enabled)) || !enabled) return;
\tannibale_goodix_inited = true;
\tif (kernel_thread_start(annibale_goodix_delayed, NULL, &thread) == KERN_SUCCESS)
\t\tthread_deallocate(thread);
}
'''
s=s.rstrip()+'\n'+wrapper
open(p,'w',encoding='utf-8').write(s)
print('wrote delayed-thread init')
import re
for i,l in enumerate(s.split('\n')):
    if re.search(r'annibale_goodix_(init|probe_now|delayed)',l): print(' ',i+1,l.strip())
