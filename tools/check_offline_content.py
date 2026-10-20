"""Offline structural/content checks; requires Python 3 only. Not a Dart compiler."""
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
chapters=json.loads((root/'assets/linux_notes.json').read_text(encoding='utf-8'))
assert isinstance(chapters,list) and chapters, 'Expected nonempty chapter list'
notes=0
for index,chapter in enumerate(chapters):
    assert isinstance(chapter,dict), f'Chapter {index} is not an object'
    assert isinstance(chapter.get('category'),str) and chapter['category'].strip(), f'Chapter {index} lacks category'
    assert isinstance(chapter.get('notes'),list), f'Chapter {index} lacks notes array'
    for j,note in enumerate(chapter['notes']):
        assert isinstance(note,dict) and isinstance(note.get('title'),str) and note['title'].strip(), f'Invalid note {index}/{j}'
        notes+=1
source=(root/'lib/offline_toolkit.dart').read_text(encoding='utf-8')
for feature in ('class OfflineToolkit','virtualChallenges','printCertificate','importedPacks','useBurmese','importPack','simulateInfra'):
    assert feature in source, f'Missing feature hook: {feature}'
assert 'const InputDecoration(labelText: tr(' not in source, 'Dynamic translation inside const InputDecoration'
assert 'const InputDecoration(prefixIcon:Icon(Icons.search),labelText:tr(' not in source
pubspec=(root/'pubspec.yaml').read_text(encoding='utf-8')
for dep in ('shared_preferences:', 'pdf:', 'printing:', 'assets/linux_notes.json'):
    assert dep in pubspec, f'Missing pubspec entry: {dep}'
print(f'PASS: {len(chapters)} chapters and {notes} notes validated; required feature hooks and dependencies found.')
print('WARNING: Does not prove Flutter compilation, device behavior, or command simulator correctness.')
