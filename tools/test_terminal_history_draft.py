from pathlib import Path
s = (Path(__file__).resolve().parents[1] / 'lib/offline_toolkit.dart').read_text()
assert "String historyDraft = '';" in s
assert 'historyDraft = command.text;' in s
assert '? historyDraft : commandHistory[historyPosition]' in s
assert "s.length <= 4096 && !s.contains('\\u0000')" in s
assert "historyDraft = '';" in s
print('PASS: terminal history draft and persistence bounds (static only)')
