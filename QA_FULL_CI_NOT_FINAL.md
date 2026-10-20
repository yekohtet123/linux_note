# CI coverage checkpoint (not final)

Fixed GitHub Actions validation job: previous workflow executed only 4 of 9 regression scripts. The new workflow discovers every `tools/test_*.py`, runs content validation and catalog audit, and stops on the first error. Added `tools/test_ci_coverage.py` to check coverage.

These are static Python tests. Flutter compilation, tests and device/browser runtime have not been run in this environment.
