import subprocess

old = open('/root/star26/s34/work/root/lib/libannibale-sbmetal-experiment.dylib', 'rb').read()
pat = b'Adreno (TM) 830'
n = old.count(pat)
print('occurrences', n, 'size', len(old))
assert n == 2
rep = b'Adreno 660' + b'\x00' * (len(pat) - len(b'Adreno 660'))
new = old.replace(pat, rep)
open('/tmp/sbmetal-patched.dylib', 'wb').write(new)
print('patched ->', len(new))
print('ldid', subprocess.run(['ldid', '-S', '/tmp/sbmetal-patched.dylib'], capture_output=True).returncode)
subprocess.run(['cp', '-f', '/tmp/sbmetal-patched.dylib',
                '/root/star26/s111/work/rootbuild/root/lib/libannibale-sbmetal-experiment.dylib'], check=True)
print('staged')
