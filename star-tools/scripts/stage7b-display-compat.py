#!/usr/bin/env python3
"""stage7b: make the ported ABI layer link, and start its services on star.

Three things are needed after stage7 copies the files in:

1. The copied display/GPU code still calls into the K90 GPU driver
   (`annibale_gpu_*` in bsd/dev/annibale/annibale_gpu_dispatch.c, which this
   tree does not carry).  On star every one of those calls must answer "no GPU"
   so AnnibaleGPU stays on its documented stub path: the service registers so
   the drawable driver has somebody to ask, every request is refused with
   kIOReturnUnsupported, and the surface is treated as the process's own
   memory -> Mesa softpipe draws.  They live in a .cpp file because IOLog is a
   C++ symbol and the .c stub file cannot call it.

2. `MiniIOMobileFramebufferStart()` / `MiniIOSurfaceStart()` were called from
   GenericARMPE.cpp in the K90 tree and stage-0 removed the calls along with
   the K90 drivers.  They come back here, plus AnnibaleGPUStartStub().

3. Nothing else changes: fb_flip / fb_dim / fb_dcs keep their default 0, so
   flip_start() returns before it maps 0x0ae00000 and the kernel never touches
   the DPU.  Frames go straight into the boot framebuffer at 0xEA600000.
"""
import os
import sys

DST = "/root/star26/star-native"
COMPAT = DST + "/iokit/Kernel/StarDisplayCompat.cpp"
CONF = DST + "/iokit/conf/files"
PE = DST + "/iokit/Kernel/GenericARMPE.cpp"

COMPAT_C = r'''/*
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

extern "C" uint32_t annibale_frames_shown = 0;
extern "C" uint32_t annibale_gpu_space = 0;     /* ring space, asked by submit */
extern "C" uint32_t gpu_log = 0;                /* boot-arg gpu_log */
extern "C" uint32_t gpu_va = 0;                 /* boot-arg gpu_va */

extern "C" void
annibale_tl(const char *format, ...)
{
	char line[256];
	va_list ap;

	va_start(ap, format);
	vsnprintf(line, sizeof(line), format, ap);
	va_end(ap);
	IOLog("%s", line);
}

/*
 * IOMobileFramebuffer::setProperties asks the backlight driver about
 * IOMFBBrightnessLevel.  star has no backlight driver yet, so the request is
 * refused the same way the K90 code refuses one it cannot serve: the caller
 * keeps the brightness it had.  No panel register is touched.
 */
IOReturn
MiniAppleARMBacklightFramebufferProperties(OSObject * properties)
{
	static unsigned said;

	(void) properties;
	if (said++ < 4) {
		IOLog("star: brightness request refused (no backlight driver yet)\n");
	}
	return kIOReturnUnsupported;
}

extern "C" bool     annibale_platform_is_annibale(void) { return false; }
extern "C" bool     annibale_gpu_ready(void) { return false; }
extern "C" bool     annibale_gpu_parameter(uint32_t which, uint64_t * value)
{
	(void) which;
	if (value != NULL) {
		*value = 0;
	}
	return false;
}
extern "C" uint64_t annibale_gpu_address(uint64_t size) { (void) size; return 0; }
extern "C" void     annibale_gpu_address_free(uint64_t address, uint64_t size)
{
	(void) address;
	(void) size;
}
extern "C" bool     annibale_gpu_map(uint64_t address, uint64_t phys, bool read_only)
{
	(void) address;
	(void) phys;
	(void) read_only;
	return false;
}
extern "C" bool     annibale_gpu_mapped(void) { return false; }
extern "C" bool     annibale_gpu_unmap(uint64_t address, uint64_t size)
{
	(void) address;
	(void) size;
	return false;
}
extern "C" void     annibale_gpu_to_memory(void * start, uint64_t size)
{
	(void) start;
	(void) size;
}
extern "C" uint32_t annibale_gpu_submit(const uint64_t * addresses,
    const uint32_t * words, uint32_t count)
{
	(void) addresses;
	(void) words;
	(void) count;
	return 0;
}
extern "C" bool     annibale_gpu_done(uint32_t fence) { (void) fence; return false; }
extern "C" uint32_t annibale_gpu_irqs(void) { return 0; }
extern "C" void     annibale_gpu_pause(uint32_t seen, uint32_t poll_us, uint32_t longest_us)
{
	(void) seen;
	(void) poll_us;
	(void) longest_us;
}
extern "C" uint32_t annibale_gpu_last(void) { return 0; }
extern "C" uint32_t adreno8_context_depth(void) { return 0; }
extern "C" void     annibale_gpu_worked(uint64_t * microseconds,
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
extern "C" void     annibale_gpu_speed(uint32_t * mhz, uint32_t * changes)
{
	if (mhz != NULL) {
		*mhz = 0;
	}
	if (changes != NULL) {
		*changes = 0;
	}
}
extern "C" void     annibale_gpu_report(const char * why) { (void) why; }
extern "C" bool     annibale_gpu_recover(void) { return false; }
extern "C" void     annibale_gpu_stop(void) {}
'''

CONF_LINE = "iokit/Kernel/StarDisplayCompat.cpp\t\toptional iokitcpp\n"
CONF_ANCHOR = "iokit/Kernel/AnnibaleGPU.cpp\t\t\t\toptional iokitcpp\n"

PE_OLD = """	/* star stage 0: no display/IOSurface services yet.  These are the
	 * first subsystem to be written against star-B.dtb (SM8350). */
	return true;
"""
PE_NEW = """	/* star: the display/GPU ABI layer (stage 7).  IOSurface and
	 * IOMobileFramebuffer are Apple's protocol, not K90 hardware; the GPU
	 * registers in its documented stub mode, so a drawable is the process's
	 * own memory and Mesa softpipe draws.  fb_flip/fb_dim/fb_dcs stay 0, so
	 * no DPU register is ever touched and every frame goes straight into
	 * the boot framebuffer at 0xEA600000. */
	MiniIOSurfaceStart(this);
	MiniIOMobileFramebufferStart(this);
	AnnibaleGPUStartStub();
	return true;
"""
PE_INCLUDE_OLD = """/* star stage 0: the K90 Mini* drivers are not in this tree.  The star
 * display/IOSurface services are wired back in here in stage 1. */
"""
PE_INCLUDE_NEW = """/* star stage 7: the display/GPU ABI layer is in this tree (MiniDrivers.h,
 * MiniIOSurface.cpp, MiniIOMobileFramebuffer.cpp, AnnibaleGPU.cpp). */
#include "MiniDrivers.h"

extern "C" bool AnnibaleGPUStartStub(void);
"""


def main():
    print("=== 1. the annibale GPU symbols, answered for star ===")
    current = open(COMPAT, encoding="utf-8").read() if os.path.exists(COMPAT) else ""
    if current == COMPAT_C:
        print("  StarDisplayCompat.cpp  up to date")
    else:
        open(COMPAT, "w", encoding="utf-8").write(COMPAT_C)
        print("  StarDisplayCompat.cpp  %d bytes%s" %
              (os.path.getsize(COMPAT), "" if not current else " (updated)"))

    print("=== 2. register it ===")
    c = open(CONF, encoding="utf-8").read()
    if "StarDisplayCompat.cpp" in c:
        print("  already registered")
    else:
        assert CONF_ANCHOR in c, "AnnibaleGPU entry not found in iokit/conf/files"
        open(CONF, "w", encoding="utf-8").write(c.replace(CONF_ANCHOR, CONF_ANCHOR + CONF_LINE))
        print("  + StarDisplayCompat.cpp")

    print("=== 3. start the services from GenericARMPE ===")
    t = open(PE, encoding="utf-8").read()
    if "MiniIOMobileFramebufferStart(this)" in t:
        print("  GenericARMPE.cpp  already patched")
    else:
        assert PE_OLD in t, "GenericARMPE.cpp does not look like the star-native tree"
        t = t.replace(PE_OLD, PE_NEW)
        if '#include "MiniDrivers.h"' not in t:
            assert PE_INCLUDE_OLD in t, "GenericARMPE.h include not found"
            t = t.replace(PE_INCLUDE_OLD, PE_INCLUDE_NEW, 1)
        open(PE, "w", encoding="utf-8").write(t)
        print("  GenericARMPE.cpp  + MiniIOSurfaceStart / MiniIOMobileFramebufferStart / AnnibaleGPUStartStub")

    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
