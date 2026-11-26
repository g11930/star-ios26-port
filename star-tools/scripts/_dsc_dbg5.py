#!/usr/bin/env python3
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
import dscsym2

img = dscsym2.image_at(0x1800EA000)
if img is None:
    print("image_at(0x1800EA000): None")
else:
    print(f"image_at(0x1800EA000): name={img[2]!r} tva=0x{img[0]:x} "
        f"tsz=0x{img[1]:x} trie={img[3]}")
print("resolve(0x1800EA000):", dscsym2.resolve(0x1800EA000))
