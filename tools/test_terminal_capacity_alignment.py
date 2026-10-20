from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib/offline_toolkit.dart').read_text()
assert 'dirs.length <= 1500' in s
assert 'savedFiles.length <= 1500 && savedModes.length <= 1500' in s
assert 'dirs.length + savedFiles.length <= 1500' in s
assert 'removed.length <= 400' in s
assert 'while (removedPaths.length > 400)' in s
assert 'removedPaths.remove(removedPaths.first)' in s
assert s.count('rememberRemovedPath(target);') == 3
assert 'removedPaths.add(target);' in s
print('Terminal capacity alignment static checks passed')
