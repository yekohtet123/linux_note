# Virtual terminal persistence checkpoint (NOT FINAL)

- Saves simulated directories, files, permissions, deleted-path markers and cwd to SharedPreferences after terminal commands.
- Restores only bounded, structurally valid JSON. Does not access host filesystem.
- Reset action confirms before wiping virtual state and verified virtual challenges. Other learning progress is retained.
- Fixes `mv file file` deleting the source.
- Needs Flutter analyzer, emulator/device test, web reload test.
