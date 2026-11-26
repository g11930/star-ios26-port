#!/bash
F=/mnt/c/ios26/s97-live.bin
echo "===== 1) s97 kernel diag lines ====="
strings -n 6 "$F" | grep -E "star_iv97|star_ex97|star_kv" | head -24
echo
echo "===== 2) counts ====="
echo -n "star_iv97 lines: "; strings "$F" | grep -c "star_iv97"
echo -n "star_ex97 lines: "; strings "$F" | grep -c "star_ex97"
echo -n "star_kv  lines: "; strings "$F" | grep -c "star_kv"
echo -n "SecTask error=22: "; strings "$F" | grep -c "SecTaskLoadEntitlements failed error=22"
echo -n "NOT_CODESIGNED : "; strings "$F" | grep -c "NOT_CODESIGNED"
echo -n "WindowServer    : "; strings "$F" | grep -ci "WindowServer"
echo -n "SpringBoard pid count lines: "; strings "$F" | grep -c "SpringBoard\["
echo
echo "===== 3) cs_flags distribution ====="
strings "$F" | grep -o "cs_flags=[0-9a-f]*" | sort | uniq -c
echo
echo "===== 4) first/last timestamps of file ====="
strings -n 8 "$F" | grep -oE "^2025-[0-9-]+ [0-9:.+]+" | sed -n '1p;$p'
echo
echo "===== 5) rwa/metal/first_frame state ====="
strings "$F" | grep -E "AnnibaleGPU|IOAcceleratorES|registration device|first_frame|RWA_SOFTWARE|metal_native" | head -12
echo
echo "===== 6) any panic / reboot / halt ====="
strings "$F" | grep -Ei "panic|haltRestart|kernel returned|boot fallback" | head -10
echo
echo "===== DONE ====="
