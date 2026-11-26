import re, sys

path = r"C:\ios26\p22-logdump.bin"
data = open(path, "rb").read()

# panic block
i = data.find(b"panic(cpu")
print("panic offset", i)
block = data[max(0, i - 700): i + 4200]
block = block.replace(b"\x00", b"\n")
txt = block.decode("latin-1")
# keep only printable-ish lines
out = []
for line in txt.split("\n"):
    line = "".join(ch if 32 <= ord(ch) < 127 else "" for ch in line).strip()
    if line:
        out.append(line)
print("\n".join(out[:120]))
