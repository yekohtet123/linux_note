from pathlib import Path
s = (Path(__file__).resolve().parents[1] / 'lib/offline_toolkit.dart').read_text()
for fragment in [
    'maxEditorChars = 32768',
    "Store.p.getString('offline_editor_draft_v1')",
    "Store.p.setString('offline_editor_draft_v1', draft)",
    'editor.addListener(saveEditorDraft)',
    'maxLength: maxEditorChars',
    'Future<void> resetEditorDraft() async',
    'if (confirmed != true || !mounted) return;',
    'editor.text = defaultEditorText;',
    'if (source.length > maxEditorChars)',
]:
    assert fragment in s, fragment
print('PASS: local scratchpad persistence and reset guards (static only)')
