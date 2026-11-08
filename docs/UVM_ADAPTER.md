# Separate reusable APB UVM adapter

The reusable environment lives in
[AMBA-Protocol-Verification at source ff158f4f7ed844f2a7ab9b3e19423ebc50be8f60](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/ff158f4f7ed844f2a7ab9b3e19423ebc50be8f60/docs/ADVANCED_APB.md).
Adapter 0 pins this repository's unchanged RTL to
`e30fd5242a1e84be92107d6be75652220748a8a7` and respects its 64-word,
low-address-bit alias, always-ready/no-error contract.

The new environment has a passive public-pin monitor, independent memory
scoreboard, deterministic sequences and concurrent assertions. A separate
coverage mode contains requirements-based covergroups; its execution and
export require the verification-feature licence. Procedural requirement hit
counts are not simulator functional coverage.

The original class/coverage environment in this repository remains intact and
**NOT RUN** while `svverification` is unavailable. Running the new deterministic
UVM environment does not establish that original environment's result or
equivalent coverage, full APB compliance, synthesis, timing or hardware behavior.

After checking out the immutable AMBA source linked above, run from its root
with Python, Git, Questa 2025.2 and its matching UVM 1.2 library:

```powershell
python scripts/run_apb_uvm.py --sim-bin C:\MXR\Quartus\25.1\questa_fse\win64 --uvm-lib C:\MXR\Quartus\25.1\questa_fse\uvm-1.2 --uvm-include C:\MXR\Quartus\25.1\questa_fse\verilog_src\uvm-1.2\src --adapters 0 --output C:\short\apb64-uvm-new
if ($LASTEXITCODE -ne 0) { throw 'APB UVM or assertion qualification failed or was blocked' }
```

Use a fresh output directory and run only one Questa session at a time on the
tested node-locked Starter licence. The runner fetches this source at its full
SHA and verifies a clean detached checkout. These documentation additions do
not change RTL, testbenches, licence, attribution or historical evidence.

## Published branch evidence

A clean detached GitHub clone passed 1,280 accepted transfers and 2,048 independent comparisons for this adapter,
plus the shared five expected-negative assertion detections and one legal
assertion control. The combined three-adapter/nine-substep wrapper exited 0.
See the [immutable raw evidence and summary](https://github.com/M-Roohan-Khan-28/AMBA-Protocol-Verification/blob/2a337d28e718f274d44b0eb7cad80efd745a1331/reports/advanced-apb-2026-11-08/SUMMARY.md).
A deliberate read-data fault produced an independent scoreboard fatal and
wrapper exit 1. Functional coverage export remains NOT RUN; no percentage is claimed.
