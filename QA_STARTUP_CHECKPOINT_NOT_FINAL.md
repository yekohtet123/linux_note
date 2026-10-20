# Startup recovery checkpoint (NOT FINAL)

- Isolated corrupt local preferences for personal notes, folders, and stats.
- Bounds-check theme and font scale to avoid startup range errors.
- Leaves damaged original preference strings untouched for recovery.
- Added three Flutter tests and a CI `flutter test` step.
- Python static validation is possible here; Flutter SDK unavailable so these tests are NOT yet executed.
