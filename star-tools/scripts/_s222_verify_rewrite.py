#!/usr/bin/env python3
"""Verify the rewritten dyld shared cache against its rewrite report."""
import sys, json, hashlib, struct, importlib.util
from pathlib import Path

SCRIPTS = Path('/root/dsc26_zeta_scripts')
def load(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f'{name}.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

rw = load('rewrite-zeta-dyld-cache')
dc = load('zeta_dyld_cache')

OUT = Path(sys.argv[1])
REPORT = Path(sys.argv[2])
PROOF = Path(sys.argv[3])

report = json.loads(REPORT.read_text())
files = report['files']
print(f"report: edits={report['edits']} files_changed={report['files_changed']} page_shift={report['page_shift']}")
print(f"files in report: {len(files)}")

missing, sha_bad, sig_bad = [], [], []
total_edits = 0
sizes = []
for f in files:
    p = OUT / f['name']
    if not p.exists():
        missing.append(f['name']); continue
    data = p.read_bytes()
    sizes.append(len(data))
    if hashlib.sha256(data).hexdigest() != f['sha256']:
        sha_bad.append(f['name'])
    cf = dc.CacheFile(p)
    off, size = cf.signature
    got = rw.verify_signature(data, off, size)
    if got != f['cdhash']:
        sig_bad.append((f['name'], got, f['cdhash']))
    total_edits += f['edits']

print(f"missing={len(missing)} sha_bad={len(sha_bad)} sig_bad={len(sig_bad)}")
if missing: print("  MISSING:", missing[:10])
if sha_bad: print("  SHA_BAD:", sha_bad[:10])
if sig_bad: print("  SIG_BAD:", sig_bad[:10])
print(f"sum edits from files={total_edits}")
if sizes:
    print(f"rewritten size total={sum(sizes):,} B ({sum(sizes)/2**30:.2f} GiB), min={min(sizes):,} max={max(sizes):,}")

# Spot check: confirm rewritten words match the proof's ordinary lowering.
import numpy as np
summary = json.loads((PROOF / 'summary.json').read_text())
checked = 0
for entry in list(summary['images'].values()) + summary['islands']:
    if not entry.get('edit_count'):
        continue
    rp = PROOF / entry['result_file']
    if not rp.exists():
        continue
    edits = np.load(rp)['edits']
    # find a rewritten file whose reported edit count matches this proof entry
    cand = [f['name'] for f in files if f['edits'] == len(edits)]
    if not cand:
        continue
    name = cand[0]
    data = (OUT / name).read_bytes()
    off = int(edits[0, 0]); orig = int(edits[0, 1] & 0xffffffff); ordinary = int(edits[0, 2] & 0xffffffff)
    got = struct.unpack_from('<I', data, off)[0]
    print(f"spot {name}: off={off:#x} orig={orig:#010x} ordinary={ordinary:#010x} got={got:#010x} {'OK' if got==ordinary else 'MISMATCH'}")
    checked += 1
    if checked >= 3:
        break

ok = not missing and not sha_bad and not sig_bad
print("VERIFY", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
