# Offline Linux Notes — CI hardening checkpoint (NOT FINAL)

- GitHub Actions validation now runs backup and simulator static contract tests, as well as the existing content checks.
- Added release-integrity regression checks to detect missing chapters, notes, category groups and feature hooks.
- Added `flutter analyze --no-fatal-infos` before Android and Web builds.
- **No claim of Flutter build success:** Flutter SDK is not installed in this environment.
- Existing source and 1,096 notes are preserved.
- These checks do not prove simulator functional correctness, PDF rendering, or Android/Web runtime behavior.
