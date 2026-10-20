from pathlib import Path
s = (Path(__file__).resolve().parents[1] / 'lib/offline_toolkit.dart').read_text()
assert 'final toCreate = <String>[];' in s
assert 'directories.addAll(toCreate);' in s
assert 'directories.length + files.length + toCreate.length > 1500' in s
assert "if (existingLength + addedLength > 4096)" in s
assert "dirs.every((d) => d == '/' || dirs.contains(parentOf(d)))" in s
assert 'savedModes.keys.every((f) => savedFiles.containsKey(f))' in s
print('PASS: atomic mkdir preflight, save-compatible file size and restore invariants (static)')
