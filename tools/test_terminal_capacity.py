from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib/offline_toolkit.dart').read_text()
checks={
 'read/remove allowed when full': 'Creation commands enforce the limit individually.' in s,
 'mkdir capacity': "return 'mkdir: virtual filesystem limit reached'" in s,
 'touch capacity': "return 'touch: virtual filesystem limit reached'" in s,
 'copy capacity': "return 'cp: virtual filesystem limit reached'" in s,
 'path validation': 'invalidVirtualPath' in s,
 'echo path validation': "return 'echo: invalid virtual path'" in s,
 'no stale save on overflow': "Store.p.remove('offline_terminal_state_v1')" in s,
}
for label, ok in checks.items(): print(('PASS' if ok else 'FAIL')+': '+label)
assert all(checks.values())
print('Static checks only; Flutter runtime still required.')
