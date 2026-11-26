#!/bin/bash
# Count ZONE_ID enum from its start to get exact numbers
grep -n "ZONE_ID_FIRST\|typedef enum.*zone_id\|enum.*zone" /root/star26/star-native/osfmk/kern/zalloc.h | head -10
echo "=== 枚举起点上下文 ==="
S=$(grep -n "ZONE_ID_NONE\|ZONE_ID_FIRST\|zone_id_t;" /root/star26/star-native/osfmk/kern/zalloc.h | head -1 | cut -d: -f1)
sed -n "$((S-5)),$((S+10))p" /root/star26/star-native/osfmk/kern/zalloc.h
echo
echo "=== 用 awk 精确数 ZONE_ID_ 枚举项序号 ==="
awk '
/zone_id_t|ZONE_ID_NONE|enum.*zone/ {inzone=1}
inzone && /^enum|^\{/ {found=1}
found && /ZONE_ID_[A-Z]/ {
  line=$0
  gsub(/^[ \t]*/,"",line)
  if (line ~ /^ZONE_ID_[A-Z_]+,?$/) {
    n=split(line,a,","); name=a[1];
    idx++;
    if (name=="ZONE_ID_IPC_PORT" || name=="ZONE_ID_TURNSTILE" || name=="ZONE_ID_SEMAPHORE" || name=="ZONE_ID_IPC_KMSG")
      print idx": "name
  }
}
' /root/star26/star-native/osfmk/kern/zalloc.h
