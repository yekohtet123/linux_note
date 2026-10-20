# Offline development status — 2026-10-20

This is a **development checkpoint, not a final release**.

Changes in this iteration:
- Fixed translated `InputDecoration` labels incorrectly placed inside `const` constructors (Dart compile-time error).
- Added bounded size/title validation for imported offline lab packs.
- Expanded the Python content checker to validate every chapter and note structure and detect these known invalid const patterns.

Still required before final release: Flutter analyzer/build, Android and Web runtime checks, comprehensive Burmese/English translation review, simulator behavior tests, and complete requirements acceptance testing. No claim is made that all 600 guided labs are executable/verifiable inside the simulator.
