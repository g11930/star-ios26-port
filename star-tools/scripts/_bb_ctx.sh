#!/bash
cd /root || exit 1
echo "===== 调用点上下文（前后 120 行）====="
llvm-objdump -d --macho backboardd.bin 2>/dev/null | sed -n '69700,69920p'
