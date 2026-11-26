#!/bin/bash
R=/root/star26/s111/work/rootbuild/root
echo "--- Applications ---"
ls $R/Applications 2>/dev/null | head -12
echo "--- Assets.car in a few apps ---"
for a in Preferences MobileSafari MobileCal MobileNotes; do
  d=$R/Applications/$a.app
  [ -d "$d" ] && echo "$a: $(ls $d | head -6 | tr '\n' ' ')"
  [ -d "$d" ] && ls $d/Assets.car 2>/dev/null
done
echo "--- icon caches ---"
ls $R/var/mobile/Library/Caches 2>/dev/null | head -10
echo "--- IconServices framework ---"
ls $R/System/Library/PrivateFrameworks/IconServices.framework 2>/dev/null | head -6
</