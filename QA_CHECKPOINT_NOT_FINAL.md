# Offline QA checkpoint (NOT FINAL)

Changes: enforce strict simulated Docker/Kubernetes command shapes; prevent duplicate Kubernetes deployment creation; make Terraform apply idempotent; add content/simulator regression checks.

Run `python tools/check_offline_content.py` and `python tools/test_offline_regressions.py`.

These Python tests do not compile Dart or test Android/Web runtime. Flutter SDK is unavailable in this environment.

Pending: Flutter analyze/build, widget/device tests, complete localization, real validation of imported lab pack persistence and certificate rendering.
