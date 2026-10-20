"""Source contract checks (not Dart runtime execution)."""
from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib/offline_toolkit.dart').read_text()
assert 'bool terraformInitialized = false;' in s
assert "case 'init': terraformInitialized = true;" in s
for action in ('plan', 'apply', 'destroy'):
    assert f"case '{action}': if (!terraformInitialized)" in s
assert "terraformInitialized ? terraformResources.join" in s
assert "args.length == 2 && args[1] == 'ps'" in s
assert "args.length == 3 && args[1]=='get'" in s
assert 'Process.run(' not in s and "import 'dart:io'" not in s
print('PASS: simulator command contracts and offline safety (static only)')
