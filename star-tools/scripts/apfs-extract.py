#!/usr/bin/env python3
"""apfs-extract.py IMAGE DIR [-v VOLUME] -- unpack a volume of an APFS image into a directory.

Contents, mode, owner, group and mtime come back, so `mkapfs.py` can make the image again
from the result.  Read only: the image is never written.

Usage:
    PYTHONPATH=<tools/apfs> python3 apfs-extract.py IMAGE DIR [-v NAME]
"""
import errno
import os
import sys

from apfs_super import *
from apfs_reader import *


def pick_volume(c, want):
    vols = c.volumes()
    if not vols:
        raise ApfsError("no volumes in this container")
    if want is None:
        for v in vols:
            if v.inode(ROOT_DIR_INO_NUM) is not None:
                return v
        return vols[0]
    for v in vols:
        if v.volname == want or str(v.index) == str(want):
            return v
    raise ApfsError("no volume named %r (have: %s)"
                    % (want, ", ".join(v.volname for v in vols)))


def main(argv):
    want = None
    args = []
    i = 1
    while i < len(argv):
        if argv[i] == "-v" and i + 1 < len(argv):
            want = argv[i + 1]
            i += 2
            continue
        args.append(argv[i])
        i += 1
    if len(args) != 2:
        sys.stderr.write("usage: apfs-extract.py IMAGE DIR [-v VOLUME]\n")
        return 2
    image, out = args[0], args[1]

    c = Container(image)
    v = pick_volume(c, want)
    print("volume %r (%d bytes of blocks, %d files, %d dirs)"
          % (v.volname, c.block_size, v.num_files, v.num_directories))

    n_dir = n_file = n_link = n_other = 0
    n_bytes = 0

    def extract_dir(oid, path):
        nonlocal n_dir, n_file, n_link, n_other, n_bytes
        for name, fid, dt in sorted(v.dir_entries(oid)):
            p = os.path.join(path, name)
            ino = v.inode(fid)
            if ino is None:
                n_other += 1
                continue
            if ino.is_dir:
                os.makedirs(p, exist_ok=True)
                n_dir += 1
                extract_dir(fid, p)
            elif ino.is_link:
                tgt = ino.symlink_target_bytes()
                if tgt is None:
                    n_other += 1
                    continue
                if os.path.lexists(p):
                    os.unlink(p)
                os.symlink(tgt.decode("utf-8", "surrogateescape"), p)
                n_link += 1
            elif ino.is_reg:
                data = ino.contents()
                with open(p, "wb") as fh:
                    fh.write(data)
                n_file += 1
                n_bytes += len(data)
            else:
                n_other += 1
                continue
            # owners and modes last, so a read-only directory does not stop its children
            try:
                os.chown(p, ino.owner, ino.group, follow_symlinks=False)
            except OSError:
                pass
            try:
                os.chmod(p, ino.mode & 0o7777)
            except OSError:
                pass
            try:
                os.utime(p, (ino.access_time / 1e9, ino.mod_time / 1e9),
                         follow_symlinks=False)
            except OSError:
                pass

    os.makedirs(out, exist_ok=True)
    extract_dir(ROOT_DIR_INO_NUM, out)
    root = v.inode(ROOT_DIR_INO_NUM)
    if root is not None:
        try:
            os.chmod(out, root.mode & 0o7777)
        except OSError:
            pass
    print("extracted: %d dirs, %d files (%d bytes), %d symlinks, %d other"
          % (n_dir, n_file, n_bytes, n_link, n_other))
    c.close()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
