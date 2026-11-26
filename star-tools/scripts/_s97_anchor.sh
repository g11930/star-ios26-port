#!/bash
cd /root/star26/star-native || exit 1
echo "===== A) kern_cs.c 78-100 ====="
sed -n '78,100p' bsd/kern/kern_cs.c
echo
echo "===== B) kern_cs.c 250-320 ====="
sed -n '250,320p' bsd/kern/kern_cs.c
echo
echo "===== C) where p_csflags set after exec ====="
grep -rn "proc_csflags_set\|proc_csflags_update" bsd/kern/kern_exec.c | head -10
echo
echo "===== D) kern_exec.c 2300-2335 ====="
sed -n '2300,2335p' bsd/kern/kern_exec.c
echo
echo "===== DONE ====="
