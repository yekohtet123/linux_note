from pathlib import Path
s=(Path(__file__).resolve().parents[1]/'lib'/'offline_toolkit.dart').read_text()
checks={
'command length bound': "cmd.length > 4096",
'filesystem entry bound': "directories.length + files.length >= 1500",
'echo directory collision': "return 'echo: destination is a directory'",
'echo file size bound': "return 'echo: virtual file size limit exceeded'",
'mkdir duplicate': "return 'mkdir: directory already exists'",
'touch directory collision': "return 'touch: destination is a directory'",
'cp directory collision': "return 'cp: destination is a directory'",
'mv directory collision': "return 'mv: destination is a directory'",
}
for label,needle in checks.items():
 assert needle in s,label
 print('PASS:',label)
print('LIMITATION: source assertions, not Dart execution')
