#!/usr/bin/env python3
p='/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s=open(p).read()
# the probe can be started late, from the first write to /dev/annibale-touch
s=s.replace('''annibale_goodix_init(void)
{
	uint32_t enabled = 0;''','''annibale_goodix_init(void)
{
	static int started;
	uint32_t enabled = 0;''',1)
s=s.replace('''	printf("goodix: init called\\n");''','''	if (started) {
		return;
	}
	started = 1;
	printf("goodix: init called\\n");''',1)
# no artificial delay now: the probe is started when userland opens the device
s=s.replace('struct timespec wait = { 75, 0 };','struct timespec wait = { 0, 0 };')
s=s.replace('goodix: thread up, probing in 75 s','goodix: thread up')
open(p,'w').write(s)

q='/root/star26/star-native/bsd/dev/star/annibale_input.c'
t=open(q).read()
if 'annibale_goodix_init();          /* started on the first write' not in t:
    t=t.replace('''touch_write(__unused dev_t dev, struct uio *uio, __unused int ioflag)
{
	struct annibale_touch t;''','''touch_write(__unused dev_t dev, struct uio *uio, __unused int ioflag)
{
	struct annibale_touch t;

	annibale_goodix_init();          /* started on the first write: the probe's prints then land late enough to be read */''',1)
    open(q,'w').write(t)
print('gated:', 'static int started' in s, 'kick:', 'first write' in t)
