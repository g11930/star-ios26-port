#!/usr/bin/env python3
d = open('/mnt/c/ios26/s200-boot.img', 'rb').read()
print('hdr', d[0:8])
if d[0:8] == b'ANDROID!':
    # boot image header v0..v2: 10 u32 fields
    import struct
    vals = struct.unpack('<10I', d[8:48])
    names = ['kernel_size','kernel_addr','ramdisk_size','ramdisk_addr','second_size','second_addr','tags_addr','page_size','header_version','os_version']
    for n, v in zip(names, vals):
        print(n, v, hex(v))
    page = vals[7]
    ksz = vals[0]
    koff = page
    print('kernel at', koff, 'size', ksz, 'first bytes', d[koff:koff+16].hex(' '))
    print('ramdisk at', koff + ((ksz + page - 1)//page)*page)
