import re

path = r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()

marks = [
    b"=== /annibale/etc/rc ===",
    b"stub service registered",
    b"first_frame at",
    b"frames in 5",
    b"END OF LOG",
    b"panic(cpu",
    b"loader_return_after",
    b"Kernel version:",
]
print("total", len(data))
for m in marks:
    offs = [x.start() for x in re.finditer(re.escape(m), data)]
    print("%-32s %s" % (m.decode(), offs[:8]))
