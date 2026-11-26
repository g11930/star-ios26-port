#!/usr/bin/env python3
p = '/root/star26/star-native/bsd/dev/star/annibale_goodix.c'
s = open(p).read()
if 'goodix: init called' not in s:
    s = s.replace('''annibale_goodix_init(void)
{
	uint32_t enabled = 0;
	thread_t thread;

	if (!PE_parse_boot_argn("touchscreen", &enabled, sizeof(enabled)) || !enabled) {
		return;
	}''', '''annibale_goodix_init(void)
{
	uint32_t enabled = 0;
	thread_t thread;
	boolean_t parsed;

	printf("goodix: init called\\n");
	parsed = PE_parse_boot_argn("touchscreen", &enabled, sizeof(enabled));
	printf("goodix: touchscreen boot-arg parsed=%d value=%u\\n", (int)parsed, enabled);
	if (!parsed || !enabled) {
		printf("goodix: leaving, the touch screen is not enabled\\n");
		return;
	}
	printf("goodix: starting the probe thread\\n");''', 1)
    s = s.replace('''	PE_parse_boot_argn("touch_flip", &flip, sizeof(flip));
	if (kernel_thread_start(goodix_thread, NULL, &thread) == KERN_SUCCESS) {
		thread_deallocate(thread);
	}''', '''	PE_parse_boot_argn("touch_flip", &flip, sizeof(flip));
	if (kernel_thread_start(goodix_thread, NULL, &thread) == KERN_SUCCESS) {
		thread_deallocate(thread);
		printf("goodix: probe thread started\\n");
	} else {
		printf("goodix: kernel_thread_start failed\\n");
	}''', 1)
    open(p, 'w').write(s)
    print('init diagnostics added')
else:
    print('already present')
