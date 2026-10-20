# Offline QA — Lab Pack Data Validation (NOT FINAL)

## Changes
- Added a shared `validatedPack` function for new imports, saved packs and backup restoration.
- Validates pack titles (1–120 chars), lab counts (1–200), lab titles (1–180 chars), and tasks (1–4000 chars).
- Discards malformed previously saved packs rather than displaying them.
- Limits restored backup JSON to 2,000,000 characters and maintains the existing 20-pack limit.
- Retains data-only handling: no imported commands are executed.

## Local checks
- `python tools/check_offline_content.py` — PASS
- `python tools/test_offline_regressions.py` — PASS
- `python tools/audit_lab_catalog.py` — PASS

## Outstanding release blockers
- Flutter SDK not available in this runtime: Android and web compilation unverified.
- Device/browser runtime, PDF rendering, backup/restore UX, full bilingual content, and simulator end-to-end tests unverified.
- 600 guided labs are not 600 independently auto-verified virtual exercises.

This checkpoint is NOT a final release.
