# Offline QA hardening — NOT FINAL

- Bounded backup list sizes (5,000 entries) and item lengths (300 characters) to reduce oversized restored state.
- Rejected non-integer values in numeric backup arrays rather than accepting string coercion.
- Capped restored quiz score values and key length.
- Prevented importing a lab pack whose title already exists.
- Added static guardrail test `tools/test_backup_validation.py`.

This is a source-level checkpoint only. Flutter compilation, PDF rendering, Android and browser tests remain unverified.
