from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib/offline_toolkit.dart').read_text()
checks={
 'local persistence key': "offline_terminal_state_v1" in s,
 'saved on execute': 'saveTerminal();' in s[s.index('void execute()'):s.index('void validate()')] and 'command.clear();' in s[s.index('void execute()'):s.index('void validate()')],
 'bounded persisted state': 'state.length <= 150000' in s and 'savedTerminal.length <= 150000' in s,
 'restore path checks': 'dirs.every(validPath)' in s and 'savedFiles.keys.every(validPath)' in s,
 'reset confirmation': 'confirmResetTerminal' in s and 'showDialog<bool>' in s,
 'reset verified labs': 'verifiedChallenges.clear();' in s,
 'same-path move guard': "if (dest == target) return '';" in s,
}
for k, v in checks.items():
 print(('PASS' if v else 'FAIL')+': '+k)
assert all(checks.values())
print('LIMITATION: source-level assertions only; Flutter runtime tests required')
