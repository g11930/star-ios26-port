/*
 * StarDisplayCompat.cpp -- the annibale symbols the ported display/GPU ABI
 * layer still references, answered for a star / SM8350 that has no GPU driver.
 *
 * iokit/Kernel/AnnibaleGPU.cpp, AnnibaleGPUMemory.inc and AnnibaleGPUSubmit.inc
 * were written for the K90 port; they call the SM8750 GPU dispatcher
 * (bsd/dev/annibale/annibale_gpu_dispatch.c) which is deliberately NOT part of
 * this tree.  None of those calls can succeed here, and none of them has to:
 * AnnibaleGPUStartStub() sets gGPUStub, and with it the service registers while
 * treating a drawable as the process's own memory, which is what makes the
 * software rasteriser the one that draws.
 *
 * Every function below therefore answers "no GPU" and touches no register.
 * annibale_tl() keeps the K90 log tag working through IOLog(), which reaches
 * the loader's live log ring the same way the rest of the kernel does.
 *
 * This file is a compatibility shim, not a driver.  When a real Adreno 660
 * driver is written against star-B.dtb, it replaces these bodies.
 */
#include <IOKit/IOLib.h>
#include <IOKit/IOReturn.h>
#include <libkern/c++/OSObject.h>
#include <sys/types.h>
#include <stdarg.h>

extern "C" __attribute__((weak)) uint32_t annibale_frames_shown = 0;
extern "C" __attribute__((weak)) uint32_t annibale_gpu_space = 0;     /* ring space, asked by submit */
extern "C" __attribute__((weak)) uint32_t gpu_log = 0;                /* boot-arg gpu_log */
extern "C" __attribute__((weak)) uint32_t gpu_va = 0;                 /* boot-arg gpu_va */

extern "C" __attribute__((weak)) void
annibale_tl(const char *format, ...)
{
	char line[256];
	va_list ap;

	va_start(ap, format);
	vsnprintf(line, sizeof(line), format, ap);
	va_end(ap);
	IOLog("%s", line);
}

/* IOMobileFramebuffer::setProperties asks the backlight driver about
 * IOMFBBrightnessLevel.  The real handler lives in MiniAppleARMBacklight.cpp
 * (restored from the P-series tree, which proved it out to first_frame); the
 * placeholder that used to sit here refused every request. */

extern "C" __attribute__((weak)) bool     annibale_platform_is_annibale(void) { return false; }
extern "C" __attribute__((weak)) bool     annibale_gpu_ready(void) { return false; }
extern "C" __attribute__((weak)) bool     annibale_gpu_parameter(uint32_t which, uint64_t * value)
{
	(void) which;
	if (value != NULL) {
		*value = 0;
	}
	return false;
}
extern "C" __attribute__((weak)) uint64_t annibale_gpu_address(uint64_t size) { (void) size; return 0; }
extern "C" __attribute__((weak)) void     annibale_gpu_address_free(uint64_t address, uint64_t size)
{
	(void) address;
	(void) size;
}
extern "C" __attribute__((weak)) bool     annibale_gpu_map(uint64_t address, uint64_t phys, bool read_only)
{
	(void) address;
	(void) phys;
	(void) read_only;
	return false;
}
extern "C" __attribute__((weak)) bool     annibale_gpu_mapped(void) { return false; }
extern "C" __attribute__((weak)) bool     annibale_gpu_unmap(uint64_t address, uint64_t size)
{
	(void) address;
	(void) size;
	return false;
}
extern "C" __attribute__((weak)) void     annibale_gpu_to_memory(void * start, uint64_t size)
{
	(void) start;
	(void) size;
}
extern "C" __attribute__((weak)) uint32_t annibale_gpu_submit(const uint64_t * addresses,
    const uint32_t * words, uint32_t count)
{
	(void) addresses;
	(void) words;
	(void) count;
	return 0;
}
extern "C" __attribute__((weak)) bool     annibale_gpu_done(uint32_t fence) { (void) fence; return false; }
extern "C" __attribute__((weak)) uint32_t annibale_gpu_irqs(void) { return 0; }
extern "C" __attribute__((weak)) void     annibale_gpu_pause(uint32_t seen, uint32_t poll_us, uint32_t longest_us)
{
	(void) seen;
	(void) poll_us;
	(void) longest_us;
}
extern "C" __attribute__((weak)) uint32_t annibale_gpu_last(void) { return 0; }
extern "C" __attribute__((weak)) uint32_t adreno8_context_depth(void) { return 0; }
extern "C" __attribute__((weak)) void     annibale_gpu_worked(uint64_t * microseconds,
    uint32_t * submissions, uint32_t by[7])
{
	if (microseconds != NULL) {
		*microseconds = 0;
	}
	if (submissions != NULL) {
		*submissions = 0;
	}
	for (int i = 0; i < 7; i++) {
		if (by != NULL) {
			by[i] = 0;
		}
	}
}
extern "C" __attribute__((weak)) void     annibale_gpu_speed(uint32_t * mhz, uint32_t * changes)
{
	if (mhz != NULL) {
		*mhz = 0;
	}
	if (changes != NULL) {
		*changes = 0;
	}
}
extern "C" __attribute__((weak)) void     annibale_gpu_report(const char * why) { (void) why; }
extern "C" __attribute__((weak)) bool     annibale_gpu_recover(void) { return false; }
extern "C" __attribute__((weak)) void     annibale_gpu_stop(void) {}
