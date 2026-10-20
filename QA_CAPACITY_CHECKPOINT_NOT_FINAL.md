# Offline terminal capacity checkpoint (NOT FINAL)

- Enforce virtual filesystem entry cap for mkdir, touch and cp; allow reading/deleting at capacity.
- Validate command virtual paths and echo redirect destinations.
- Avoid retaining a stale persisted terminal snapshot after serialization exceeds size limit.
- Static regression checks only; Flutter/Dart compilation and runtime remain unverified.
