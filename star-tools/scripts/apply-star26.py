#!/usr/bin/env python3
"""iOS 26 system volume deployment for star (Xiaomi 11 Ultra) - OFFLINE BY DEFAULT.

Nothing is written unless the subcommand is given --confirm CONFIRM.

Subcommands
  check     read-only: re-read GPT from device, verify baseline, verify images, print plan
  gpt       write the 4 GPT blocks (split darwin -> darwin + darwin_var)
  system    write os.dmg / systemos.dmg / appos.dmg into darwin, zero darwin_var metadata
  verify    read-only: hash the written ranges on device and compare with local images
  rollback  restore the original GPT blocks captured before any write

The plan keeps Android userdata (2785280..51849727) COMPLETELY UNCHANGED, so
no f2fs resize is needed. Only GPT entries 36 and 37 change.
"""
import argparse
import base64
import hashlib
import os
import shutil
import struct
import subprocess
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT / '系统卷'
BLOCKS = ROOT / 'gpt' / 'blocks'
ADB = Path('D:/桌面/adb-fastboot/adb.exe')
SERIAL = 'e95b466e'
BS = 4096
CHUNK = 256 * 1024 * 1024          # 256 MiB per adb push
SCRATCH = Path('C:/wbtmp/star26-chunks')   # ASCII path: adb push with CJK paths is fragile
DEVICE_TMP = '/data/local/tmp/star26-chunk.bin'

DARWIN_FIRST = 51849728
DARWIN_VAR_FIRST = 56044032
LAST_USABLE = 61844474
TOTAL_BLOCKS = 61844480          # blockdev --getsize64 / 4096, measured
TAIL_FIRST_LBA = 61844472        # dd skip used when capturing gpt-tail.bin (8 blocks, ends at backup header)

# name, local file, LBA (absolute), size in bytes
IMAGES_PLAN = [
    ('os.dmg',        DARWIN_FIRST + 0,       9758048256),
    ('systemos.dmg',  DARWIN_FIRST + 2382336, 5261754368),
    ('appos.dmg',     DARWIN_FIRST + 3666944, 14680064),
]
EXPECTED_SHA = {
    'os.dmg':       '6fd8b6cfea6cdca8b3ef6e6e5847cd12f7a301207cd8c31b1877600d3dfcb2e7',
    'systemos.dmg': '48f22bc4e265db11d42f5604f36e77cbac94b5ab372ecf9dceb88079a1aa346d',
    'appos.dmg':    'a2feda1141c5ee58eb0fd75660b95a3ba69b52c95f2ecf2eaa2dc4a14bf7ec2b',
}
GPT_WRITES = [
    ('backup-entries.bin',  61844475, 2),
    ('backup-header.bin',   61844479, 1),
    ('primary-entries.bin', 2,        2),
    ('primary-header.bin',  1,        1),
]


def adb(*args, timeout=120, binary=False):
    cmd = [str(ADB), '-s', SERIAL, *[str(a) for a in args]]
    env = dict(os.environ, MSYS_NO_PATHCONV='1')
    r = subprocess.run(cmd, capture_output=True, timeout=timeout, env=env)
    if r.returncode:
        raise RuntimeError(f'adb {" ".join(map(str,args))[:120]} failed: '
                           f'{r.stdout.decode("utf-8","replace")[-400:]} {r.stderr.decode("utf-8","replace")[-400:]}')
    return r.stdout if binary else r.stdout.decode('utf-8', 'replace')


def sh(script, timeout=1800):
    return adb('shell', f"su -c '{script}'", timeout=timeout)


def read_blocks(lba, count):
    """Read raw blocks through base64 (adb exec-out corrupts binary on this device)."""
    out = adb('shell', f"su -c 'dd if=/dev/block/sda bs=4096 skip={lba} count={count} 2>/dev/null | base64'",
              timeout=180)
    raw = ''.join(out.split())
    data = base64.b64decode(raw)
    assert len(data) == count * BS, f'expected {count*BS} bytes, got {len(data)}'
    return data


def file_sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def confirm(args, what):
    if args.confirm != 'CONFIRM':
        print(f'DRY RUN - {what} NOT executed. Pass --confirm CONFIRM to write.')
        return False
    return True


def cmd_check(args):
    print('=== 1. device ===')
    print(adb('devices').strip())
    print('root:', sh('id').strip())
    size = int(sh('blockdev --getsize64 /dev/block/sda').strip())
    print(f'LUN0 = {size} B = {size//BS} blocks; expected {TOTAL_BLOCKS}')
    assert size // BS == TOTAL_BLOCKS, 'device geometry changed - STOP'

    print('=== 2. baseline GPT (must match captured backup) ===')
    head = read_blocks(0, 8)
    tail = read_blocks(TAIL_FIRST_LBA, 8)
    assert head == (ROOT / 'gpt' / 'gpt-head.bin').read_bytes(), 'primary GPT differs from backup - STOP'
    assert tail == (ROOT / 'gpt' / 'gpt-tail.bin').read_bytes(), 'backup GPT differs from backup - STOP'
    print('primary + backup GPT byte-identical to captured baseline: PASS')
    p = head[BS:BS + 92]
    assert p[:8] == b'EFI PART'
    print(f'  entries CRC = {hex(struct.unpack_from("<I", p, 88)[0])}')

    print('=== 3. images ===')
    for name, lba, size_b in IMAGES_PLAN:
        f = IMAGES / name
        if not f.is_file():
            print(f'  {name}: MISSING ({f})')
            continue
        got, want = f.stat().st_size, size_b
        digest = file_sha(f)
        print(f'  {name}: {got} B (want {want}) sha256 {digest[:16]} '
              f'size_ok={got==want} hash_ok={digest==EXPECTED_SHA[name]}')
        assert got == want and digest == EXPECTED_SHA[name], f'{name} bad - STOP'

    print('=== 4. plan ===')
    print(f'  darwin      {DARWIN_FIRST}..{DARWIN_VAR_FIRST-1}   16.000 GiB  (three containers)')
    print(f'  darwin_var  {DARWIN_VAR_FIRST}..60238335        16.000 GiB  (ANNFS001 /private/var)')
    print('  userdata    2785280..51849727                187.166 GiB  UNCHANGED, no f2fs resize')
    print('  GPT entries changed: [36] new darwin_var, [37] darwin shrunk; other 35 untouched')
    for name, lba, size_b in IMAGES_PLAN:
        print(f'  {name:14} -> LBA {lba} .. {lba + size_b//BS - 1}')
    print('  darwin_var first 64 MiB will be zeroed (ANNFS001 metadata slots)')
    print('CHECK PASSED - safe to proceed with --confirm CONFIRM')


def write_blocks_to_device(local_path, lba, count):
    """Push a file and dd it to an absolute LBA, then read back and compare."""
    SCRATCH.mkdir(parents=True, exist_ok=True)
    tmp = SCRATCH / 'chunk.bin'
    shutil.copyfile(local_path, tmp)
    adb('push', tmp, DEVICE_TMP, timeout=1800)
    sh(f'dd if={DEVICE_TMP} of=/dev/block/sda bs=4096 seek={lba} '
       f'count={count} conv=notrunc,fsync 2>/dev/null', timeout=1800)
    back = read_blocks(lba, count)
    want = tmp.read_bytes()[:count * BS]
    assert back == want, f'readback mismatch at LBA {lba}'
    sh(f'rm -f {DEVICE_TMP}')
    tmp.unlink()
    print(f'  LBA {lba} x{count}: written and read back OK')


def cmd_gpt(args):
    print('=== GPT write ===')
    print('Order: backup entries -> backup header -> primary entries -> primary header')
    print('(a power loss at any point leaves one complete old or new table)')
    if not confirm(args, 'GPT write'):
        for name, lba, count in GPT_WRITES:
            print(f'  would write {name} -> LBA {lba} ({count} blocks)')
        return
    head = read_blocks(0, 8)
    assert head == (ROOT / 'gpt' / 'gpt-head.bin').read_bytes(), 'baseline changed - STOP'
    for name, lba, count in GPT_WRITES:
        write_blocks_to_device(BLOCKS / name, lba, count)
    # full verification
    assert read_blocks(0, 8) == (ROOT / 'gpt' / 'gpt-head.new').read_bytes(), 'primary mismatch'
    assert read_blocks(TAIL_FIRST_LBA, 8) == (ROOT / 'gpt' / 'gpt-tail.new').read_bytes(), 'backup mismatch'
    print('GPT APPLIED AND VERIFIED.')


def write_large_image(path, lba):
    total = path.stat().st_size
    SCRATCH.mkdir(parents=True, exist_ok=True)
    tmp = SCRATCH / 'chunk.bin'
    done = 0
    with open(path, 'rb') as src:
        while done < total:
            length = min(CHUNK, total - done)
            data = src.read(length)
            assert len(data) == length and length % BS == 0
            tmp.write_bytes(data)
            adb('push', tmp, DEVICE_TMP, timeout=1800)
            chunk_lba = lba + done // BS
            sh(f'dd if={DEVICE_TMP} of=/dev/block/sda bs=4096 seek={chunk_lba} '
               f'count={length//BS} conv=notrunc,fsync 2>/dev/null', timeout=1800)
            back = read_blocks(chunk_lba, length // BS)
            assert back == data, f'readback mismatch at LBA {chunk_lba}'
            done += length
            print(f'  {path.name}: {done}/{total} bytes ({100*done/total:.1f}%)', flush=True)
    sh(f'rm -f {DEVICE_TMP}')
    tmp.unlink(missing_ok=True)


def cmd_system(args):
    print('=== system volume write ===')
    print('darwin LBA 51849728..56044031 (16 GiB); 3 containers = 14.002 GiB')
    if not confirm(args, 'system volume write'):
        for name, lba, size_b in IMAGES_PLAN:
            print(f'  would write {name} ({size_b} B) -> LBA {lba}')
        print(f'  would zero darwin_var LBA {DARWIN_VAR_FIRST}..{DARWIN_VAR_FIRST+16383} (64 MiB)')
        return
    # ensure the new table is live before writing into the new ranges
    head = read_blocks(0, 8)
    if head != (ROOT / 'gpt' / 'gpt-head.new').read_bytes():
        print('ERROR: new GPT is not on the device. Run "gpt --confirm CONFIRM" first.')
        sys.exit(2)
    for name, lba, size_b in IMAGES_PLAN:
        f = IMAGES / name
        assert f.stat().st_size == size_b and file_sha(f) == EXPECTED_SHA[name], f'{name} bad'
        print(f'writing {name} -> LBA {lba}')
        write_large_image(f, lba)
    # zero the two 32 MiB ANNFS001 metadata slots
    print('zeroing darwin_var first 64 MiB')
    zero = SCRATCH / 'zero.bin'
    zero.write_bytes(bytes(64 * 1024 * 1024))
    adb('push', zero, DEVICE_TMP, timeout=1800)
    sh(f'dd if={DEVICE_TMP} of=/dev/block/sda bs=4096 seek={DARWIN_VAR_FIRST} '
       f'count=16384 conv=notrunc,fsync 2>/dev/null', timeout=1800)
    sh(f'rm -f {DEVICE_TMP}')
    zero.unlink()
    print('SYSTEM VOLUME WRITTEN. Run "verify" next.')


def cmd_verify(args):
    print('=== verify written ranges (device-side sha256, no bulk transfer) ===')
    for name, lba, size_b in IMAGES_PLAN:
        out = sh(f'dd if=/dev/block/sda bs=4096 skip={lba} count={size_b//BS} 2>/dev/null | sha256sum',
                 timeout=1800)
        got = out.split()[0]
        want = EXPECTED_SHA[name]
        print(f'  {name:14} device={got[:16]} local={want[:16]} match={got==want}')
        assert got == want, f'{name} verification FAILED'
    print('ALL THREE CONTAINERS MATCH ON DEVICE')


def cmd_rollback(args):
    print('=== rollback GPT to captured baseline ===')
    if not confirm(args, 'GPT rollback'):
        for name, lba, count in GPT_WRITES:
            print(f'  would restore orig-{name} -> LBA {lba}')
        return
    for name, lba, count in GPT_WRITES:
        write_blocks_to_device(BLOCKS / f'orig-{name}', lba, count)
    assert read_blocks(0, 8) == (ROOT / 'gpt' / 'gpt-head.bin').read_bytes()
    assert read_blocks(TAIL_FIRST_LBA, 8) == (ROOT / 'gpt' / 'gpt-tail.bin').read_bytes()
    print('GPT ROLLED BACK AND VERIFIED')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest='cmd', required=True)
    for n in ('check', 'gpt', 'system', 'verify', 'rollback'):
        p = sub.add_parser(n)
        p.add_argument('--confirm', default='', help='must be CONFIRM for any write')
    args = ap.parse_args()
    {'check': cmd_check, 'gpt': cmd_gpt, 'system': cmd_system,
     'verify': cmd_verify, 'rollback': cmd_rollback}[args.cmd](args)


if __name__ == '__main__':
    main()
