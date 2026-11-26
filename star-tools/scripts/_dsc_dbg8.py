#!/usr/bin/env python3
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
import dscsym2

img = dscsym2.image_at(0x1BE041F18)
print("image_at(0x1BE041F18):",
    "None" if img is None else
    f"name={img[2]!r} tva=0x{img[0]:x} tsz=0x{img[1]:x} trie={img[3]}")
print("resolve:", dscsym2.resolve(0x1BE041F18))
