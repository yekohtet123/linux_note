# Offline Learning Toolkit — incremental implementation

The existing notes, 600 new guided labs, progress, quiz and bookmarks remain in the source. Added `lib/offline_toolkit.dart` and a sidebar entry.

Implemented locally (no cloud/API key):
- A **limited virtual terminal** (`pwd`, `ls`, `cd`, `mkdir`, `touch`, `cat`, `echo`, `rm`, `whoami`, `clear`, `help`). This does not execute commands on the device and does not emulate Linux kernel semantics.
- 10-skill career roadmap and 100-day manual completion calendar stored with SharedPreferences.
- 6 incident troubleshooting walkthroughs, revealable hints, local practice badges.
- A local code scratchpad with *basic* heuristic checks and clipboard copy. Not a real YAML/Bash/HCL parser or runtime.
- A static infrastructure topology walkthrough.
- Local achievement badges and **export-only** progress backup via JSON clipboard.
- Search across bundled notes and labs.

Already present in prior edition: MCQ quiz, bookmarks, completed labs, dashboard, challenge command reveal, difficulty filter.

Not yet fully implemented: real shell/VM, auto-verification against a real Linux host, full code language parsers, import of external lab packs, progress backup restore, generated PDF certificates, fully translated English content. These require additional work and/or platform-specific libraries. Real Docker/Kubernetes/Terraform execution is deliberately not claimed.

Android/web builds have not been run in this environment because Flutter SDK is unavailable. Build locally with `flutter pub get` then `flutter build apk --release` or `flutter build web --release --base-href /linux_note/`.
