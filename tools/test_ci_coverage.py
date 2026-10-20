from pathlib import Path
root = Path(__file__).resolve().parents[1]
workflow = (root / '.github/workflows/build.yml').read_text()
assert 'for script in tools/check_offline_content.py tools/audit_lab_catalog.py tools/test_*.py; do' in workflow
assert 'python "$script"' in workflow
assert 'set -euo pipefail' in workflow
for required in ['flutter analyze --no-fatal-infos', 'flutter test', 'flutter build apk --release', "flutter build web --release --base-href '/linux_note/'"]:
    assert required in workflow, required
scripts = list((root / 'tools').glob('test_*.py'))
assert len(scripts) >= 10, len(scripts)
print(f'PASS: CI discovers {len(scripts)} Python regression scripts and runs Flutter checks (static)')
