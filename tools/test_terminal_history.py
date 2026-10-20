from pathlib import Path
s = (Path(__file__).resolve().parents[1] / 'lib/offline_toolkit.dart').read_text()
for phrase in ['final commandHistory = <String>[];', 'maxTerminalLogLines = 250', 'maxCommandHistory = 80', 'void recallCommand(int direction)', 'commandHistory.last != s', 'log.removeRange(0, log.length - maxTerminalLogLines)', "if (s.isEmpty) return;", "tooltip: 'Previous command'", "tooltip: 'Next command'", 'commandHistory.clear();']:
    assert phrase in s, phrase
print('PASS: terminal command history and bounded log source checks (static only)')
