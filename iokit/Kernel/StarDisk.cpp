/*
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
#include <libkern/libkern.h>

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

/*
 * The device table libignition reads through vfs.generic.apfs.edt_fstab: every
 * volume of the container, by the role its superblock carries.  Filled as the
 * volumes are published; bsd/miscfs/apfs/apfs_vfsops.c serves it verbatim.
 */
#define STAR_EDT_FSTAB_COUNT 8
#define STAR_EDT_DEVNAME_LEN 32

struct star_edt_fstab_entry {
	char     dev_name[STAR_EDT_DEVNAME_LEN];
	uint32_t role;
	uint32_t flags;
};

static struct star_edt_fstab_entry gStarEdt[STAR_EDT_FSTAB_COUNT];
static int gStarEdtCount;

/* C ABI for bsd/miscfs/apfs/apfs_vfsops.c */
extern "C" int
StarDiskVolumeTable(void * out, int max_entries)
{
	struct star_edt_fstab_entry * e = (struct star_edt_fstab_entry *)out;
	int i, n = 0;

	if (out == NULL || max_entries <= 0) {
		return gStarEdtCount;
	}
	for (i = 0; i < gStarEdtCount && n < max_entries; i++) {
		e[n++] = gStarEdt[i];
	}
	return n;
}


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
		if (gStarEdtCount < STAR_EDT_FSTAB_COUNT) {
			struct star_edt_fstab_entry * e = &gStarEdt[gStarEdtCount++];
			strlcpy(e->dev_name, bsdname, sizeof(e->dev_name));
			e->role = roleMask;
			e->flags = writable ? 1 : 0;
		}
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
