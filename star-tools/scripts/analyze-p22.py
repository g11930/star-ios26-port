import re, sys, os

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()
print("file %s  %d bytes" % (path, len(data)))


def find(tag, pat, limit=6, window=200):
    hits = [m.start() for m in re.finditer(pat, data)]
    print("\n--- %s : %d hit(s)" % (tag, len(hits)))
    for h in hits[:limit]:
        s = data[max(0, h - 40): h + window]
        s = s.replace(b"\x00", b" ").replace(b"\r", b" ")
        print("   ", s.decode("latin-1")[:window].strip())


find("stub registered", rb"stub service registered")
find("no drawable", rb"no drawable \(\d+\)")
find("client-memory copy failed", rb"client-memory copy allocation failed")
find("client-memory import", rb"annibaledrawable: client")
find("no connection", rb"no connection to AnnibaleGPU")
find("NOT_CODESIGNED", rb"NOT_CODESIGNED")
find("first_frame", rb"first_frame at")
find("swap", rb"swap \d+ layer \d+")
find("panic", rb"panic\(|Debugger called|initproc failed")
find("launchd", rb"launchd\.ios")

# timeline of the important swap / progress lines
print("\n=== all swap lines ===")
for m in re.finditer(rb"swap (\d+) layer", data):
    s = data[max(0, m.start() - 90): m.start() + 120].replace(b"\x00", b" ")
    print("   ", s.decode("latin-1").strip())
    if m.start() > 0 and len(re.findall(rb"swap ", data)) > 40:
        pass
print("swap total:", len(re.findall(rb"swap \d+ layer", data)))
