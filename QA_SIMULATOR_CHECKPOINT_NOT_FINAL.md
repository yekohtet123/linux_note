# Simulator QA checkpoint — NOT FINAL

- Terraform simulation now requires `terraform init` before plan/apply/destroy/state list.
- Docker `ps` and `images` reject trailing unsupported arguments.
- Kubernetes `get deployments` rejects trailing unsupported arguments.
- Added `tools/test_simulator_contract.py` static contract checks.
- These are simulated commands, not real infrastructure operations.
- Flutter compiler, browser/Android runtime, and PDF rendering have not been verified.
