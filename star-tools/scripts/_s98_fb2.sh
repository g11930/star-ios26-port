#!/bash
python3 - <<'PY'
d=open("/mnt/c/ios26/s98-frame.raw","rb").read()
nz=sum(1 for b in d if b)
print("len",len(d),"nonzero",nz)
print("first bytes",d[:16].hex())
PY
echo "===== SpringBoard 里程碑 ====="
strings -n 8 /mnt/c/ios26/s98-live.bin | grep -Ei "didFinishLaunching|workspace|SBApplication|SBScene|SBWindow|startup|bootstrap complete|UISystem" | tail -20
