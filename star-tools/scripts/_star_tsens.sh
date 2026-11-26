#!/bin/bash
echo "===== star 侧 tsens 基础设施 ====="
grep -rn -E "tsens_base|TSENS_GPU|tsens_groups|TSENS_STATUS|TSENS_VALID|TSENS_STALE_MS|TSENS_SENSORS|TSENS_GROUPS|tsens_hottest" /root/star26/star-native/bsd/dev/annibale/ /root/star26/star-native/bsd/sys/ /root/star26/star-native/bsd/dev/star/ 2>/dev/null | head -30
echo
echo "===== star 侧 annibale_cpufreq.c 是否存在 ====="
ls -la /root/star26/star-native/bsd/dev/annibale/annibale_cpufreq.c 2>&1
echo
echo "===== star 侧 annibale_cpufreq.c 里的 tsens / temperature ====="
grep -n -E "tsens|temperature|TSENS" /root/star26/star-native/bsd/dev/annibale/annibale_cpufreq.c 2>/dev/null | head -30
