from pathlib import Path
s = (Path(__file__).resolve().parents[1] / 'lib/offline_toolkit.dart').read_text()
checks = {
    'reject duplicate restored directories': 'dirs.toSet().length == dirs.length',
    'reject duplicate restored tombstones': 'removed.toSet().length == removed.length',
    'limit combined restored nodes': 'dirs.length + savedFiles.length <= 1500',
    'enforce restored path segment limit': "p.split('/').every((segment) => segment.length <= 128)",
    'enforce echo destination segment limit': "dest.split('/').any((segment) => segment.length > 128)",
    'clear recreated ancestor tombstones': 'removedPaths.removeAll(toCreate)',
}
for name, fragment in checks.items():
    assert fragment in s, name
print('PASS: six terminal restore and path integrity source checks (static only)')
