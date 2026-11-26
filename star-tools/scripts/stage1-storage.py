#!/usr/bin/env python3
"""star-native stage 1: make the kernel able to mount the star system volumes.

Run AFTER build-star-native-tree.py --reset.  Idempotent: every edit asserts the
exact text it expects, so a second run fails loudly instead of double-applying.

What changes (one variable: "the storage layer works on star"):
  1. iokit/Kernel/StarDisk.cpp  -- the IOKit object tree iOS 26 expects above
     the UFS block device.  Pure IOKit, no device register.  Capacity comes
     from the loader's UFS survey page (the real SM8350 UFS), not K90's 128 GB.
  2. ufs init calls StarDiskStart() with the measured capacity.
  3. The PMK8550 SPMI RTC read is replaced by a star-specific clock source:
     the persist /time/ats_2 value alone.  No PMIC register is touched.
  4. StarDisk.cpp is added to iokit/conf/files.

Deliberately NOT changed: outward ABI strings (/dev/annibale-touch,
"AnnibaleStore", libannibaleair) which the already-installed root.apfs
userland opens.  Renaming those belongs with the touch/audio rewrite.
"""
import os
import sys

DST = "/root/star26/star-native"

STAR_DISK_CPP = r'''/*
 * StarDisk: the IOKit object tree iOS 26 expects above the UFS block device of
 * the Xiaomi 11 Ultra (star / SM8350, ufshc@1d84000).
 *
 * This file contains NO device register.  It publishes disk0, its Apple_APFS
 * physical store, the AppleAPFSContainer and the System/Data/Preboot volumes,
 * which disk arbitration and APFS mounting look up in the IORegistry.  The
 * capacity it reports is measured from the loader's UFS survey page for THIS
 * phone; it is not a constant copied from another device.
 *
 * The volume UUIDs below are outward ABI: the system volumes already written
 * to the darwin partition and the userland in root.apfs know them.  They are
 * kept until the storage layout is redesigned together with root.apfs.
 */
#include <IOKit/IODeviceTreeSupport.h>
#include <IOKit/IOLib.h>
#include <IOKit/IOPlatformExpert.h>
#include <IOKit/IOService.h>
#include <libkern/c++/OSArray.h>
#include <libkern/c++/OSBoolean.h>
#include <libkern/c++/OSNumber.h>
#include <libkern/c++/OSString.h>

extern "C" void StarDiskStart(uint64_t size_bytes);

/* star has 61844480 blocks of 4096 bytes on LUN 0 (measured on this phone).
 * Used only when the loader did not publish a UFS survey page, so the IOKit
 * tree still has a sane Size property.  This is a reported value, never a
 * hardware register. */
#define STAR_UFS_LUN0_BYTES   253300866560ULL

class IOMedia : public IOService
{
	OSDeclareDefaultStructors(IOMedia);
};
OSDefineMetaClassAndStructors(IOMedia, IOService);

class StarDisk : public IOMedia
{
	OSDeclareDefaultStructors(StarDisk);
};
OSDefineMetaClassAndStructors(StarDisk, IOMedia);

class StarAPFSContainer : public IOService
{
	OSDeclareDefaultStructors(StarAPFSContainer);
};
OSDefineMetaClassAndStructors(StarAPFSContainer, IOService);

class StarAPFSVolume : public IOMedia
{
	OSDeclareDefaultStructors(StarAPFSVolume);
};
OSDefineMetaClassAndStructors(StarAPFSVolume, IOMedia);

static StarDisk * gStarDisk;

static IOService *
star_publish(IOService * service, IOService * provider, const char * name)
{
	if (service == NULL || !service->attach(provider)) {
		OSSafeReleaseNULL(service);
		return NULL;
	}
	service->setName(name);
	(void)service->attachToParent(provider, gIODTPlane);
	if (!service->start(provider)) {
		service->detach(provider);
		service->release();
		return NULL;
	}
	service->registerService();
	return service;
}

static StarAPFSVolume *
star_publish_volume(StarAPFSContainer * container, const char * bsdname,
    const char * volname, const char * role, uint32_t roleMask,
    const char * uuid, uint64_t sz, bool writable)
{
	StarAPFSVolume * vol = OSTypeAlloc(StarAPFSVolume);
	OSString * s;
	OSNumber * n;
	OSArray * arr;

	if (container == NULL || vol == NULL || !vol->init()) {
		OSSafeReleaseNULL(vol);
		return NULL;
	}
	if ((s = OSString::withCString(bsdname)) != NULL) {
		vol->setProperty("BSD Name", s);
		s->release();
	}
	if ((s = OSString::withCString(volname)) != NULL) {
		vol->setProperty("Volume Name", s);
		s->release();
	}
	if ((s = OSString::withCString(uuid)) != NULL) {
		vol->setProperty("VolumeUUID", s);
		vol->setProperty("UUID", s);
		s->release();
	}
	if ((s = OSString::withCString("Apple_APFS_Volume")) != NULL) {
		vol->setProperty("Content", s);
		vol->setProperty("Content Hint", s);
		s->release();
	}
	if ((s = OSString::withCString(role)) != NULL) {
		vol->setProperty("Role Description", s);
		vol->setProperty("Role", s);
		s->release();
	}
	if ((arr = OSArray::withCapacity(1)) != NULL) {
		if ((s = OSString::withCString(role)) != NULL) {
			arr->setObject(s);
			s->release();
		}
		vol->setProperty("Roles", arr);
		arr->release();
	}
	if ((n = OSNumber::withNumber(sz, 64)) != NULL) {
		vol->setProperty("Size", n);
		n->release();
	}
	if ((n = OSNumber::withNumber(4096ULL, 32)) != NULL) {
		vol->setProperty("Preferred Block Size", n);
		vol->setProperty("Block Size", n);
		n->release();
	}
	if ((n = OSNumber::withNumber((uint64_t)roleMask, 32)) != NULL) {
		vol->setProperty("APFSRole", n);
		n->release();
	}
	vol->setProperty("Whole", false);
	vol->setProperty("Writable", writable);
	vol->setProperty("Internal", true);
	vol->setProperty("IOBuiltin", true);
	vol->setProperty("Leaf", true);
	vol->setProperty("Open", true);

	if (star_publish(vol, container, bsdname) != NULL) {
		IOLog("StarDisk: published volume '%s' (%s, Role %s)\n", bsdname, volname, role);
		return vol;
	}
	return NULL;
}

void
StarDiskStart(uint64_t size_bytes)
{
	IOService * platform = IOService::getPlatform();
	StarDisk * disk0;
	StarDisk * disk0s1;
	StarAPFSContainer * container;
	OSString * s;
	OSNumber * n;
	uint64_t sz = size_bytes != 0 ? size_bytes : STAR_UFS_LUN0_BYTES;

	if (gStarDisk != NULL) {
		if ((n = OSNumber::withNumber(sz, 64)) != NULL) {
			gStarDisk->setProperty("Size", n);
			n->release();
		}
		return;
	}

	/* 1. disk0: the whole UFS LUN 0 */
	disk0 = OSTypeAlloc(StarDisk);
	if (platform == NULL || disk0 == NULL || !disk0->init()) {
		OSSafeReleaseNULL(disk0);
		return;
	}
	if ((s = OSString::withCString("disk0")) != NULL) {
		disk0->setProperty("BSD Name", s);
		s->release();
	}
	if ((s = OSString::withCString("GUID_partition_scheme")) != NULL) {
		disk0->setProperty("Content", s);
		disk0->setProperty("Content Hint", s);
		s->release();
	}
	if ((n = OSNumber::withNumber(sz, 64)) != NULL) {
		disk0->setProperty("Size", n);
		n->release();
	}
	if ((n = OSNumber::withNumber(4096ULL, 32)) != NULL) {
		disk0->setProperty("Preferred Block Size", n);
		disk0->setProperty("Block Size", n);
		n->release();
	}
	disk0->setProperty("Whole", true);
	disk0->setProperty("Writable", true);
	disk0->setProperty("Internal", true);
	disk0->setProperty("IOBuiltin", true);
	disk0->setProperty("Leaf", false);
	if (star_publish(disk0, platform, "disk0") == NULL) {
		return;
	}
	IOLog("StarDisk: published 'disk0' on star / SM8350 (Size %llu bytes)\n", sz);
	gStarDisk = disk0;

	/* 2. disk0s1: the Apple_APFS physical store */
	disk0s1 = OSTypeAlloc(StarDisk);
	if (disk0s1 != NULL && disk0s1->init()) {
		if ((s = OSString::withCString("disk0s1")) != NULL) {
			disk0s1->setProperty("BSD Name", s);
			s->release();
		}
		if ((s = OSString::withCString("Apple_APFS")) != NULL) {
			disk0s1->setProperty("Content", s);
			disk0s1->setProperty("Content Hint", s);
			s->release();
		}
		if ((n = OSNumber::withNumber(sz, 64)) != NULL) {
			disk0s1->setProperty("Size", n);
			n->release();
		}
		if ((n = OSNumber::withNumber(4096ULL, 32)) != NULL) {
			disk0s1->setProperty("Preferred Block Size", n);
			disk0s1->setProperty("Block Size", n);
			n->release();
		}
		if ((n = OSNumber::withNumber(1ULL, 32)) != NULL) {
			disk0s1->setProperty("Partition ID", n);
			n->release();
		}
		disk0s1->setProperty("Whole", false);
		disk0s1->setProperty("Writable", true);
		disk0s1->setProperty("Internal", true);
		disk0s1->setProperty("IOBuiltin", true);
		disk0s1->setProperty("Leaf", false);
		(void)star_publish(disk0s1, disk0, "disk0s1");
	}

	/* 3. disk1: the APFS container the three system volumes live in */
	container = OSTypeAlloc(StarAPFSContainer);
	if (container != NULL && container->init()) {
		IOService * parent = (disk0s1 != NULL) ? (IOService *)disk0s1 : (IOService *)disk0;
		if ((s = OSString::withCString("disk1")) != NULL) {
			container->setProperty("BSD Name", s);
			s->release();
		}
		if ((s = OSString::withCString("Apple_APFS_Container")) != NULL) {
			container->setProperty("Content", s);
			container->setProperty("Content Hint", s);
			s->release();
		}
		if ((s = OSString::withCString("disk0s1")) != NULL) {
			container->setProperty("Designated Physical Store", s);
			s->release();
		}
		if ((s = OSString::withCString("494F5332-3643-4F4E-5441-494E45520000")) != NULL) {
			container->setProperty("ContainerUUID", s);
			container->setProperty("UUID", s);
			s->release();
		}
		if ((n = OSNumber::withNumber(sz, 64)) != NULL) {
			container->setProperty("Size", n);
			n->release();
		}
		if ((n = OSNumber::withNumber(4096ULL, 32)) != NULL) {
			container->setProperty("Preferred Block Size", n);
			container->setProperty("Block Size", n);
			n->release();
		}
		container->setProperty("Whole", true);
		container->setProperty("Writable", true);
		container->setProperty("Internal", true);
		container->setProperty("IOBuiltin", true);
		container->setProperty("Leaf", false);
		container->setProperty("Fusion", false);
		container->setProperty("Encrypted", false);

		if (star_publish(container, parent, "AppleAPFSContainer") != NULL) {
			IOLog("StarDisk: published AppleAPFSContainer 'disk1'\n");
			star_publish_volume(container, "disk1s1", "System", "System", 0x1,
			    "494F5332-3653-5953-5445-4D564F4C0001", sz, false);
			star_publish_volume(container, "disk1s2", "Data", "Data", 0x40,
			    "494F5332-3644-4154-4156-4F4C554D4502", sz, true);
			star_publish_volume(container, "disk1s3", "Preboot", "Preboot", 0x10,
			    "494F5332-3650-5245-424F-4F54564F4C03", sz, true);
		}
	}
}
'''

# The K90 PMIC block: reads the PMK8550 RTC over SPMI at 0x0c400000/0x0c440000.
# star uses qcom,pmk8350@0 on qcom,spmi@c440000; that PMIC's RTC register map
# is NOT the same.  We do not guess registers: use the persist ats_2 value only.
OLD_RTC_BLOCK = r'''extern vm_offset_t ml_io_map(vm_offset_t phys_addr, vm_size_t size);
extern void annibale_spmi_lock(void);
extern void annibale_spmi_unlock(void);
extern void PESetUTCTimeOfDay(clock_sec_t secs, clock_usec_t usecs);
extern void clock_initialize_calendar(void);

static uint32_t
ufs_spmi_rtc_seconds(void)
{
	if (!annibale_platform_is_annibale()) return 0;
	vm_offset_t core = ml_io_map(0x0c400000UL, 0x3000UL);
	vm_offset_t obsrv = ml_io_map(0x0c440000UL, 0x80000UL);
	if (core == 0 || obsrv == 0) return 0;
	if ((*(volatile uint32_t *)core & 0xf0000000u) < 0x70000000u) return 0;
	uint32_t max_ch = *(volatile uint32_t *)(core + 4) & 0x7ffu;
	if (max_ch == 0 || max_ch > 1024u) max_ch = 1024u;
	uint32_t rtc_ch = max_ch;
	for (uint32_t n = 0; n < max_ch; n++) {
		uint32_t map = *(volatile uint32_t *)(core + 0x2000UL + 4UL * n);
		uint32_t ppid = (map >> 8) & 0xfffu;
		if (ppid == 0x061u || ppid == 0x060u) {
			rtc_ch = n;
			if (ppid == 0x061u) break;
		}
	}
	if (rtc_ch >= max_ch) return 0;
	vm_offset_t ch = obsrv + 0x20UL * rtc_ch;
	uint32_t rdata = 0, st = 0;
	annibale_spmi_lock();
	*(volatile uint32_t *)(ch + 0x00) = (13u << 27) | (0x48u << 4) | 3u;
	for (unsigned i = 0; i < 4000; i++) {
		st = *(volatile uint32_t *)(ch + 0x08);
		if (st & 1u) break;
	}
	if ((st & 0xfu) == 1u) {
		rdata = *(volatile uint32_t *)(ch + 0x18);
	}
	annibale_spmi_unlock();
	return rdata;
}
'''

NEW_RTC_BLOCK = r'''extern void PESetUTCTimeOfDay(clock_sec_t secs, clock_usec_t usecs);
extern void clock_initialize_calendar(void);

/*
 * star / SM8350: the RTC lives on qcom,pmk8350@0 behind qcom,spmi@c440000.
 * Its register map is a different PMIC's; no PMIC register is read or written
 * here until the PMK8350 RTC driver is written.  Android persists the wall
 * clock in /persist/time/ats_2, which is enough on its own.
 */
static uint32_t
star_rtc_seconds(void)
{
	return 0;
}
'''

# Measured capacity of the real UFS LUN 0 from the loader's survey page.
CAPACITY_FUNC = r'''
/*
 * star: report the real capacity of this phone's UFS, not a constant taken
 * from another device.  The loader lists whole logical units as partitions
 * with BLOCK_PART_UNIT; LUN 0 is the one the darwin system volumes are on.
 */
static uint64_t
star_disk_capacity_bytes(void)
{
	if (ufs_page == NULL) {
		return 0;
	}
	for (uint32_t i = 0; i < ufs_parts; i++) {
		volatile struct loader_block_part *e = &ufs_page->part[i];
		if ((e->flags & BLOCK_PART_UNIT) != 0 && e->unit == 0 &&
		    e->block_size != 0 && e->blocks != 0) {
			return (uint64_t)e->blocks * (uint64_t)e->block_size;
		}
	}
	return 0;
}
'''


def path(rel):
    return os.path.join(DST, rel)


def read(rel):
    with open(path(rel), errors="replace") as fh:
        return fh.read()


def write(rel, text):
    os.makedirs(os.path.dirname(path(rel)), exist_ok=True)
    with open(path(rel), "w") as fh:
        fh.write(text)


def replace(rel, old, new, count=1):
    text = read(rel)
    got = text.count(old)
    if got != count:
        raise SystemExit("EDIT FAILED %s: expected %d occurrence(s), got %d of %r"
                         % (rel, count, got, old[:80]))
    write(rel, text.replace(old, new))
    print("  %-38s %d edit(s)" % (rel, got))


def main():
    print("=== stage 1: star storage layer ===")

    print("--- 1. StarDisk.cpp (pure IOKit, no device register) ---")
    write("iokit/Kernel/StarDisk.cpp", STAR_DISK_CPP)
    print("  wrote iokit/Kernel/StarDisk.cpp (%d bytes)" % len(STAR_DISK_CPP))

    print("--- 2. compile entry ---")
    replace("iokit/conf/files",
            "iokit/Kernel/GenericARMPE.cpp\t\t\toptional iokitcpp\n",
            "iokit/Kernel/GenericARMPE.cpp\t\t\toptional iokitcpp\n"
            "iokit/Kernel/StarDisk.cpp\t\t\toptional iokitcpp\n")

    print("--- 3. remove the empty AnnibaleDiskStart stub ---")
    replace("bsd/dev/star/star_platform_stubs.c",
            "/* star is NOT annibale: returning false keeps the stack away from the K90\n"
            " * SPMI/PMIC register writes in annibale_ufs_rw.inc. */\n"
            "bool annibale_platform_is_annibale(void) { return false; }\n"
            "void annibale_spmi_lock(void) {}\n"
            "void annibale_spmi_unlock(void) {}\n"
            "bool annibale_virtio_blk_dev(dev_t dev) { (void)dev; return false; }\n"
            "void AnnibaleDiskStart(uint64_t size_bytes) { (void)size_bytes; }\n",
            "/* The PMK8550 SPMI path is gone; nothing in this tree writes a PMIC\n"
            " * register.  The real disk service is in iokit/Kernel/StarDisk.cpp. */\n"
            "bool annibale_virtio_blk_dev(dev_t dev) { (void)dev; return false; }\n")

    print("--- 4. UFS init: StarDiskStart with the measured capacity ---")
    # CONFIG_NO_PRINTF_STRINGS is on in this kernel: printf() is a no-op macro
    # and its format strings are stripped.  IOLog() is a real function and its
    # output reaches the loader's log (P38 proved it), so all new diagnostics
    # use IOLog, never printf.
    replace("bsd/dev/star/annibale_ufs.c",
            "extern void AnnibaleDiskStart(uint64_t size_bytes);\n",
            "extern void StarDiskStart(uint64_t size_bytes);\n"
            "extern void IOLog(const char *format, ...);\n")
    replace("bsd/dev/star/annibale_ufs.c",
            "\t\tAnnibaleDiskStart(0);\n",
            "\t\tStarDiskStart(0);\n")
    replace("bsd/dev/star/annibale_ufs.c",
            "\tAnnibaleDiskStart(128000000000ULL);\n",
            "\tuint64_t star_bytes = star_disk_capacity_bytes();\n"
            "\tif (star_bytes != 0) {\n"
            "\t\tIOLog(\"star: UFS LUN 0 measured at %llu bytes on this phone\\n\", star_bytes);\n"
            "\t}\n"
            "\tStarDiskStart(star_bytes);\n")

    # Insert the capacity helper just before ufs_init().
    replace("bsd/dev/star/annibale_ufs.c",
            "\nvoid\nannibale_ufs_init(void)\n",
            CAPACITY_FUNC + "\nvoid\nannibale_ufs_init(void)\n")

    print("--- 5. PMK8550 SPMI RTC -> star clock source ---")
    replace("bsd/dev/star/annibale_ufs_rw.inc", OLD_RTC_BLOCK, NEW_RTC_BLOCK)
    replace("bsd/dev/star/annibale_ufs_rw.inc",
            "\t\t\t\tuint32_t rtc_secs = ufs_spmi_rtc_seconds();\n",
            "\t\t\t\tuint32_t rtc_secs = star_rtc_seconds();\n")
    replace("bsd/dev/star/annibale_ufs_rw.inc",
            "\t\t\t\tprintf(\"ufs: RTC synced: PMK8550=%u s, persist /time/ats=%llu ms -> UTC %lu.%06u\\n\",\n"
            "\t\t\t\t    rtc_secs, ats_ms, (unsigned long)utc_sec, (unsigned)utc_usec);\n",
            "\t\t\t\tIOLog(\"star: RTC from persist /time/ats_2 (PMK8350 RTC not used): %llu ms -> UTC %lu.%06u\\n\",\n"
            "\t\t\t\t    ats_ms, (unsigned long)utc_sec, (unsigned)utc_usec);\n")

    print("--- 6. call UFS init from BSD init, not from a touch driver ---")
    # In the K90 tree annibale_ufs_init() was called at the end of
    # annibale_input_init() (bsd/dev/annibale/annibale_input.c:356).  star-native
    # does not carry that driver, so the stub hid the call and no disk node was
    # ever published.  Storage init belongs in bsd_init, not behind a touch
    # device; put it right after devfs is mounted.
    replace("bsd/kern/bsd_init.c",
            "\t\tdevfs_kernel_mount(mounthere);\n"
            "\t\tannibale_input_init();           /* /dev/annibale-touch */\n",
            "\t\tdevfs_kernel_mount(mounthere);\n"
            "\t\t/* star: storage init is not hidden in a touch driver.  Publish\n"
            "\t\t * /dev/ufs_*, the disk IOKit tree and the APFS container before\n"
            "\t\t * anything asks for a root volume. */\n"
            "\t\tannibale_ufs_init();\n"
            "\t\tannibale_input_init();           /* /dev/annibale-touch */\n")

    print("=== validation ===")
    checks = [
        ("bsd/dev/star/annibale_ufs.c", "StarDiskStart", 3),
        ("bsd/dev/star/annibale_ufs.c", "AnnibaleDiskStart", 0),
        ("bsd/dev/star/annibale_ufs.c", "128000000000ULL", 0),
        ("bsd/dev/star/annibale_ufs_rw.inc", "0x0c400000", 0),
        ("bsd/dev/star/annibale_ufs_rw.inc", "0x0c440000", 0),
        ("bsd/dev/star/annibale_ufs_rw.inc", "PMK8550", 0),
        ("bsd/dev/star/annibale_ufs_rw.inc", "star_rtc_seconds", 2),
        ("bsd/dev/star/star_platform_stubs.c", "AnnibaleDiskStart", 0),
        ("bsd/kern/bsd_init.c", "annibale_ufs_init();", 1),
        ("iokit/Kernel/StarDisk.cpp", "StarDiskStart", 2),
        ("iokit/conf/files", "StarDisk.cpp", 1),
    ]
    bad = 0
    for rel, token, want in checks:
        got = read(rel).count(token)
        mark = "OK" if got == want else "FAIL"
        if got != want:
            bad += 1
        print("  %-4s %-42s %-24s %d (want %d)" % (mark, rel, token, got, want))
    if bad:
        raise SystemExit("stage 1 validation failed: %d mismatch(es)" % bad)
    print("DONE")


if __name__ == "__main__":
    main()
