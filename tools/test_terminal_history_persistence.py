from pathlib import Path
s = (Path(__file__).resolve().parents[1] / 'lib/offline_toolkit.dart').read_text()
assert "Store.p.getStringList('offline_terminal_history_v1')" in s
assert "Store.p.setStringList('offline_terminal_history_v1', commandHistory)" in s
assert "Store.p.remove('offline_terminal_history_v1')" in s
assert 'savedHistory.length <= maxCommandHistory' in s
assert 'entry.length <= 4096' in s
assert 'historyPosition = commandHistory.length;' in s
print('PASS: bounded offline command history persistence source checks (static only)')
