# Terminal persistence capacity guard (not final)

The virtual terminal now snapshots its in-memory filesystem before each command and rolls back mutations when the JSON representation would exceed the 150,000-character offline persistence limit. The rejected command shows a clear terminal error. This prevents a successful-looking command from causing terminal state to be discarded on the next launch.

Validation is static Python source inspection; Flutter SDK and device runtime checks are pending.
