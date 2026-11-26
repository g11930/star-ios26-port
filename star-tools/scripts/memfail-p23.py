import re, sys

path = sys.argv[1] if len(sys.argv) > 1 else r"C:\ios26\p23-staged.bin"
data = open(path, "rb").read().replace(b"\x00", b"\n").decode("latin-1")

hits = list(re.finditer(r"client-memory copy allocation failed", data))
print("hits:", len(hits))
for i, m in enumerate(hits):
    s = data[max(0, m.start() - 500): m.start() + 300]
    s = re.sub(r"\s+", " ", s)
    print("\n--- #%d ---" % i)
    print(s.strip()[:800])
