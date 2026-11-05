# Portable APB RAM regression — 5 November 2026

## Scope and provenance

The original RTL, class-based `tb/tb_top.sv` (including randomization and covergroup), scripts and historical logs remain byte-for-byte unchanged from `hdl-labs` commit `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. This run used the published extraction base commit `839ae73b4a81b5d58364a3fbd2884f121356e572` plus the new portable testbench and wrapper on this PR branch.

The original environment failed to check out the verification-feature licence at elaboration (`vsim-1`) in ModelSim 2020.1, and the same `svverification` licence was unavailable in Questa Altera Starter FPGA Edition 2025.2. The portable bench does not replace or alter that environment.

## Command and actual outcome

Simulator: ModelSim Intel FPGA Starter Edition `vsim 2020.1 Simulator 2020.02 Feb 28 2020`; compiler: `vlog 2020.1 Compiler 2020.02 Feb 28 2020`.

From the repository root in PowerShell, with `C:\intelFPGA\20.1\modelsim_ase\win32aloem` prepended to PATH:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_portable.ps1
```

The recorded invocation supplied `-OutputDir C:\R_MIGRATION_BACKUP\Roohan_GitHub_Launch_Kit\Roohan_GitHub_Launch_Kit\build\test-runs\2026-11-05\portable-apb-interface-verification-modelsim2020` so the original repository logs stayed untouched. The wrapper's exit code was **0**. Its raw [compile log](../reports/portable-2026-11-05/compile.log) and [simulation log](../reports/portable-2026-11-05/simulation.log) show zero errors, `$finish`, and `PORTABLE_TEST_PASS APB checks=1317`.

The plain bench maintains its own 64-word expected memory. It reads all 64 words after reset, writes and reads back every word with deterministic distinct data, checks the first and last address, tests SETUP and ACCESS observations, constant `PREADY=1` and `PSLVERR=0`, idle/write read-data masking, write guards when unselected or in abandoned SETUP, and asynchronous reset during a would-be write followed by another full memory read. It also records that the RTL aliases addresses by `PADDR[7:2]`; unaligned probes describe this implementation, **not** valid APB protocol coverage. Every check uses four-state mismatch detection. A time limit and `$fatal(1)` stop on failure; the wrapper rejects error/fatal log lines or a missing completion marker. A temporary, **uncommitted** `PREADY=0` mutation produced an APB mismatch and wrapper exit code **1**, confirming failure propagation.

This is a zero-wait-state, no-error educational memory design. The portable tests do not verify wait states, error responses, arbitrary master behavior or full APB compliance. They provide no functional-coverage percentage and do not establish that the original class-based environment passes. No synthesis, timing or hardware result is claimed.
