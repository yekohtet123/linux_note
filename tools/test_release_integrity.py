"""Release content and offline boundaries; source checks only, not runtime tests."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
chapters = json.loads((root/'assets/linux_notes.json').read_text(encoding='utf-8'))
assert len(chapters) >= 236, f'Unexpected chapter regression: {len(chapters)}'
notes = [n for c in chapters for n in c['notes']]
assert len(notes) >= 1096, f'Unexpected note regression: {len(notes)}'
assert all(isinstance(n.get('title'),str) and n['title'].strip() for n in notes)
assert all(isinstance(c.get('group'),str) and c['group'].strip() for c in chapters), 'Missing group: chapter hidden by filters'
source = '\n'.join(p.read_text(encoding='utf-8') for p in (root/'lib').glob('*.dart'))
for token in ('printCertificate', 'Printing.layoutPdf', 'verifiedChallenges', 'importedPacks', 'terraformInitialized'):
    assert token in source, f'Release feature missing: {token}'
assert 'Process.run(' not in source, 'Unexpected local shell execution'
print(f'PASS: {len(chapters)} chapters, {len(notes)} notes; core offline release hooks present')
print('LIMITATION: source-only verification; Flutter build and device/browser testing required')
