#!/bin/bash
# S93: 只读扫描所有 CS_VALID / CS_PLATFORM_BINARY / CS_ADHOC / CS_SIGNED 置位或清除点
T=/root/star26/star-native
echo "=== TREE: $T ==="
echo
echo "=== A. minisandbox_check_exec 定义与调用 ==="
grep -rn 'minisandbox_check_exec' $T --include=*.c --include=*.h --include=*.cpp 2>/dev/null | head -40
echo
echo "=== B. csflags 清 CS_VALID (&= ~) 全部位置 ==="
grep -rn 'csflags *&= *~' $T --include=*.c --include=*.h 2>/dev/null | head -60
echo
echo "=== C. CS_PLATFORM_BINARY 出现处 ==="
grep -rn 'CS_PLATFORM_BINARY' $T --include=*.c --include=*.h 2>/dev/null | head -60
echo
echo "=== D. CS_ADHOC 出现处 ==="
grep -rn 'CS_ADHOC' $T --include=*.c --include=*.h 2>/dev/null | head -60
echo
echo "=== E. cs_flags 置 CS_SIGNED / CS_VALID 出现处 (含 csb_flags/csflags) ==="
grep -rn 'cs_flags *|= *CS_SIGNED\|csflags *|= *CS_SIGNED\|cs_flags *|= *CS_VALID\|csflags *|= *CS_VALID\|csb_flags *|= *CS_VALID' $T --include=*.c --include=*.h 2>/dev/null | head -60
echo
echo "=== F. 0x04000000 / 0x20000000 / 0x00000001 硬编码附近有 cs 关键字 ==="
grep -rn '0x04000000' $T --include=*.c --include=*.h 2>/dev/null | grep -i 'cs\|flag\|code' | head -40
echo
echo "=== G. mac_vnode_check_signature 定义/调用 ==="
grep -rn 'mac_vnode_check_signature' $T --include=*.c --include=*.h 2>/dev/null | head -40
echo
echo "=== DONE ==="
