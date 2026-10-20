from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib/offline_toolkit.dart').read_text()
assert 'final beforeDirs = Set<String>.of(directories);' in s
assert 'final beforeFiles = Map<String, String>.of(files);' in s
assert 'final beforeModes = Map<String, String>.of(modes);' in s
assert 'final beforeRemoved = Set<String>.of(removedPaths);' in s
assert 'final beforeCwd = cwd;' in s
assert 'if (encodedState.length > 150000)' in s
assert 'directories..clear()..addAll(beforeDirs);' in s
assert 'files..clear()..addAll(beforeFiles);' in s
assert 'modes..clear()..addAll(beforeModes);' in s
assert 'removedPaths..clear()..addAll(beforeRemoved);' in s
assert 'cwd = beforeCwd;' in s
print('Terminal persistence atomicity source checks passed')
