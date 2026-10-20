from pathlib import Path
s=(Path(__file__).resolve().parents[1]/"lib/offline_toolkit.dart").read_text()
checks={
 "unsupported flags rejected": "unsupported option ${flags.first}" in s,
 "no extra rm operands": "if (args.length != 1) return 'rm: expected one file'" in s,
 "no extra cd operands": "if (args.length > 1) return 'cd: expected at most one path'" in s,
 "protect cwd ancestors": "cwd.startsWith('$target/')" in s,
 "protect home": "target == '/home'" in s,
 "echo newline accounted": "final addedLength = content.length + 1" in s,
 "echo overwrite accounted": "redirect.group(2) == '>>' ? (files[dest]?.length ?? 0) : 0" in s,
 "echo capacity check": "return 'echo: virtual filesystem limit reached'" in s,
}
for name, ok in checks.items():
 print(("PASS" if ok else "FAIL")+": "+name)
assert all(checks.values())
print("Static contract checks only; Dart runtime not executed.")
