"""Audit bundled learning content without Flutter or external dependencies.

Run: python tools/audit_lab_catalog.py
This checks data structure and category coverage, not command execution.
"""
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
chapters = json.loads((ROOT / 'assets/linux_notes.json').read_text(encoding='utf-8'))
assert isinstance(chapters, list) and chapters, 'Catalog must contain chapters'

counts = Counter()
missing = []
empty = []
for ci, chapter in enumerate(chapters):
    category = chapter.get('category')
    group = chapter.get('group')
    notes = chapter.get('notes')
    assert isinstance(category, str) and category.strip(), f'Invalid category at {ci}'
    assert isinstance(group, str) and group.strip(), f'Invalid group at {ci}'
    assert isinstance(notes, list), f'Invalid notes list at {ci}'
    if not notes:
        empty.append(category)
    counts[group] += len(notes)
    for ni, note in enumerate(notes):
        assert isinstance(note, dict), f'Invalid note {ci}/{ni}'
        for field in ('title', 'desc'):
            if not isinstance(note.get(field), str) or not note[field].strip():
                missing.append(f'{ci}/{ni}: {field}')
        commands = note.get('cmds', [])
        assert isinstance(commands, list), f'Invalid commands at {ci}/{ni}'
        for command in commands:
            assert isinstance(command, dict), f'Invalid command at {ci}/{ni}'
            assert isinstance(command.get('c'), str), f'Invalid command text at {ci}/{ni}'

print(f'Chapters: {len(chapters)}; notes/labs: {sum(counts.values())}')
for group, total in counts.most_common():
    print(f'  {group}: {total}')
if empty:
    print(f'WARNING: {len(empty)} empty chapters')
if missing:
    print(f'WARNING: {len(missing)} missing title/description fields; first 10: {missing[:10]}')
assert not missing, 'Some notes lack required title/description'
print('PASS: catalog structure and required descriptions')
