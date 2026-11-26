#!/bin/bash
cd /tmp || exit 1
CC=/root/xnu26-test/bin/xnu26-clang
cat > t2.c <<'EOF'
extern int g(int);
int f(int a)
{
	int b[8];
	for (int i = 0; i < 8; i++) {
		b[i] = g(a + i);
	}
	return b[0] + b[7];
}
EOF
echo "=== arm64e (with XNU_TARGET_TRIPLE) ==="
XNU_TARGET_TRIPLE=arm64e-apple-ios16.5 "$CC" -O2 -c t2.c -o t2e.o
llvm-objdump -d t2e.o | sed -n '4,20p'
echo "=== arm64 (default) ==="
"$CC" -O2 -c t2.c -o t2a.o
llvm-objdump -d t2a.o | sed -n '4,20p'
echo "=== which clang actually runs ==="
XNU_TARGET_TRIPLE=arm64e-apple-ios16.5 "$CC" -### -c t2.c -o /dev/null 2>&1 | grep -o -- '-target [^ ]*' | head -3
echo "=== -arch vs -target both given ==="
XNU_TARGET_TRIPLE=arm64e-apple-ios16.5 "$CC" -O2 -arch arm64e -c t2.c -o t2x.o 2>&1 | head -3
llvm-objdump -d t2x.o | sed -n '4,20p'
