import struct
d = open('/root/star26/star-B.dtb','rb').read()
print('size', len(d))
hdr = struct.unpack_from('>10I', d, 0)
names = ['magic','totalsize','off_dt_struct','off_dt_strings','off_mem_rsvmap','version','last_comp','boot_cpuid','size_dt_strings','size_dt_struct']
for n, v in zip(names, hdr):
    print(n, v if n != 'magic' else hex(v))
