"""Static regression checks; these are NOT runtime Flutter tests."""
import json, re
from pathlib import Path
r=Path(__file__).resolve().parents[1]
data=json.loads((r/'assets/linux_notes.json').read_text(encoding='utf-8'))
assert len(data)==236, f'Unexpected chapter count: {len(data)}'
assert sum(len(x['notes']) for x in data)==1096
assert all(isinstance(x.get('notes'),list) for x in data)
assert all(isinstance(n.get('title'),str) and n['title'].strip() for x in data for n in x['notes'])
s=(r/'lib/offline_toolkit.dart').read_text(encoding='utf-8')
assert len(re.findall(r"^  \[.*?,.*?,.*?,.*?\],$",s,re.M)) >= 20, 'Missing virtual challenges'
for name in ('docker','kubectl','terraform','importPack','restoreBackup','printCertificate','challengePassed','void dispose()'):
    assert name in s, f'Missing {name}'
assert 'Deployment already exists' in s
assert 'already present, simulation' in s
assert "args.length == 5 && args[1] == 'run'" in s
assert 'Process.run(' not in s and 'dart:io' not in s, 'Simulator must not execute host commands'
print('PASS: content totals, 20 virtual challenges, simulator safety hooks, duplicate protection, lifecycle hooks')
print('LIMITATION: static checks only; Flutter build and device tests still required')
