"""Static guardrails for offline backup/import. Not a Dart runtime test."""
from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib/offline_toolkit.dart').read_text(encoding='utf-8')
assert "v.length > 5000" in s
assert "x.length > 300" in s or "(x as String).length > 300" in s
assert "v.any((e)=>e is! int)" in s
assert "(entry.value as int) > 100000" in s
assert "A pack with this title already exists" in s
assert "validatedPack(item)" in s
assert "Process.run(" not in s
print('PASS: backup limits, strict numeric fields, duplicate-pack guard, data-only imports')
print('LIMITATION: static checks; run Flutter tests and device tests before release')
