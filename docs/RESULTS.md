# APB 64-word contract results — 7 November 2026

Tested source commit: `9ed002bbb9dc93b312acb22826335d83daf834e2`.
Simulator: ModelSim Intel FPGA Starter Edition `vsim 2020.1 Simulator
2020.02 Feb 28 2020`. Deterministic xorshift32 data seed: `0x28AB6407`.
The runner bounds each external command to 120 seconds and requires exact
PASS markers, `$finish`, zero simulator errors and warnings, and a zero
process exit. ModelSim can return process exit 0 after `$fatal`, so the
transcript checks are necessary. Source hashes and command lines are in
[`results.json`](../reports/technical-completion-2026-11-07/results.json).

| Executed suite | Actual result |
| --- | --- |
| Preserved portable | PASS, 1,317 checks |
| Independent RAM contract | PASS, 2,697 comparisons; 673 issued and accepted transfers, 153 writes, 520 reads, 80 alias probes, 5 back-to-back cases, 3 reset cases |
| Protocol negative | PASS, 3 isolated malformed-master detections and 1 legal back-to-back control |
| Short measured wave run | PASS, 4 transfers and 14 comparisons |

The [raw passing logs and JSON](../reports/technical-completion-2026-11-07/)
are separate from historical reports. Three disposable monitor mutants
removed one detection each. Each retained the portable and positive contract
PASS, then raised `APB64_NEGATIVE_UNDETECTED` with wrapper exit **1**.
A disposable RTL mutant that suppressed continuous-`PSEL` writes retained
the old portable PASS but raised `APB64_MISMATCH` in the independent contract,
also with wrapper exit **1**. The fault directories contain their mutant
sources, hashes, logs and results. No mutant is part of the active source.

The [measured SVG](../reports/technical-completion-2026-11-07/apb64-directed.svg)
was rendered from the [actual simulator VCD](../reports/technical-completion-2026-11-07/apb64-directed.vcd).
Its metadata JSON names top `apb64_contract_test`, 1 ps tick units, 0–120 ns
selection, exact signal map and VCD SHA-256. The renderer makes no functional
PASS claim; that comes from the simulation log.

Reproduce from a clean checkout at the tested source with a fresh directory:

```powershell
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir C:\short\apb64-run-unique -CaptureWave
if ($LASTEXITCODE -ne 0) { throw 'APB64 regression failed or blocked' }
```

The original advanced class environment remains **NOT RUN** because this
Starter licence lacks its verification features. These checks do not establish
complete APB compliance, code or functional coverage closure, synthesis,
timing, FPGA operation or hardware behaviour.
