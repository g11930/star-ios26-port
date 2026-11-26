#!/bash
python3 - <<'PY'
for t in ("s109", "s107", "s105"):
    d = open("/mnt/c/ios26/%s-live.bin" % t, "rb").read()
    print("==", t)
    for k in (b"IOAcceleratorES lookup", b"registration failed",
              b"IOAcceleratorES: published", b"registration completed device="):
        print("  %-32s first=%8d last=%8d" % (k.decode(), d.find(k), d.rfind(k)))
PY
</bash>
