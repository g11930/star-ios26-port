import re

p = '/root/star26/hackios-xnu-userland/userland/src/inject/sbtrace.c'
s = open(p).read()
if 'sbmetal_late_load' in s:
    print('already patched'); raise SystemExit

anchor = '__attribute__((constructor)) static void\n'
assert anchor in s

block = '''
/*
 * The experiment's own registration runs from a dyld constructor, which is before the
 * process has a Metal backend: MTLCreateSystemDefaultDevice() hands back AnnibaleMetalDevice,
 * but -mesaDevice answers nil that early, so the adoption test fails on a nil name
 * ("native default device backend mismatch", device=0).  Loading the same library a few
 * seconds later, once libannibaleair is resident, gives the backend time to exist.
 */
static void *sbmetal_late_load(void *unused)
{
	const char *flag = "/annibale/etc/sbmetal-late";
	const char *air = "/annibale/lib/libannibaleair.dylib";
	const char *exp = "/annibale/lib/libannibale-sbmetal-experiment.dylib";

	if (access(flag, F_OK) != 0) return NULL;

	void *air_image = NULL;
	for (int i = 0; i < 120 && air_image == NULL; i++) {
		air_image = dlopen(air, RTLD_NOW | RTLD_NOLOAD);
		if (air_image == NULL) usleep(200 * 1000);
	}
	say("late: %s air resident=%d after %d00 ms", g_prog, air_image != NULL, 200);

	for (int i = 0; i < 5; i++) usleep(1000 * 1000);

	void *image = dlopen(exp, RTLD_NOW);
	if (image == NULL) {
		say("late: %s experiment dlopen failed: %s", g_prog, dlerror());
		return NULL;
	}
	void *ctor = dlsym(image, "sbmetal_late_entry");
	say("late: %s experiment loaded image=%p entry=%p", g_prog, image, ctor);
	return NULL;
}

'''

s = s.replace(anchor, block + anchor, 1)

# spawn the thread at the end of the constructor, right before its closing brace
tail = '\tsay("trace: %s ctor done", g_prog);\n}'
assert tail in s
new_tail = ('\tsay("trace: %s ctor done", g_prog);\n'
            '\t{\n\t\tpthread_t late;\n'
            '\t\tif (pthread_create(&late, NULL, sbmetal_late_load, NULL) == 0) pthread_detach(late);\n\t}\n}')
s = s.replace(tail, new_tail, 1)
open(p, 'w').write(s)
print('sbtrace patched with deferred experiment load')
