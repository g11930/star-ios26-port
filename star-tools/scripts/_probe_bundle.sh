#!/bin/bash
R=/root/star26/s48/work/root
echo "== AnnibaleMetal bundle in image =="
ls -ld "$R"/lib/AnnibaleMetal.bundle 2>/dev/null
ls -l "$R"/lib/AnnibaleMetal.bundle/ 2>/dev/null
echo "== /System/Library/Extensions (image side) =="
ls -l "$R"/System/Library/Extensions 2>/dev/null | head -5
echo "== symlink/alias to AnnibaleMetal in ramdisk System part =="
find "$R" -maxdepth 6 -name "AnnibaleMetal*" 2>/dev/null | head -10
echo "== does image reference /System/Library/Extensions/AnnibaleMetal =="
grep -rl "AnnibaleMetal.bundle" "$R"/lib/*.dylib 2>/dev/null | head -5
