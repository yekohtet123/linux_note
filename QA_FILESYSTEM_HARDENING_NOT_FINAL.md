# Virtual filesystem hardening (not final)

- Reject commands over 4096 characters and filesystem models beyond 1500 entries.
- Reject echo/touch/cp/mv when destination is an existing virtual directory.
- Reject creating an already-existing directory without `-p`.
- Limit simulated file content written through echo to 32768 characters.
- All changes remain within the in-memory simulator.
- Static checks only: Flutter/Dart unavailable in this environment.
