# APB RAM with SystemVerilog interface

**Verilog / SystemVerilog · RTL and verification exercise**

This standalone repository preserves the original `apb-interface` exercise from my `hdl-labs` collection. Original RTL, testbench, simulator scripts and existing evidence are preserved byte-for-byte. This packaging step is not a new simulation or a claim of full protocol compliance.

## Overview and original documentation

Extract interface-based design and tests. State implemented APB revision/subset, reset, setup/access sequencing and wait-state scope.

See [the original exercise README](SOURCE_README.md) for its existing specification, source layout and tool instructions. The text above identifies review goals; it does not claim that new enhancements have already been implemented.

## Run

From the repository root, with the required ModelSim/Questa executables and appropriate licence available:

```bash
bash sim/run.sh
```

Existing Windows instructions, where supplied, are retained in `scripts/`. Do not assume the testbench will run in every edition of a simulator. Check [the retained validation report](source-docs/VALIDATION.md) and the original README.

### Portable deterministic regression

With `vlib`, `vlog`, and `vsim` on PATH, run from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_portable.ps1
```

This compiles only the unchanged RTL and [plain testbench](tb/tb_portable.sv), writing fresh output to the ignored `portable-results/` directory. It checks all 64 RAM words after reset, deterministic write/readback, setup and access timing, constant response signals, write guards, low-address-bit aliasing, and reset during a pending write. See [portable validation](docs/portable_validation.md) and its [fresh logs](reports/portable-2026-11-05/). The original class-based environment, randomization and covergroup remain as they were; the portable checks are not equivalent coverage or complete APB protocol verification.

## Verification status

The original `reports/compile.log` and `reports/simulation.log` are historical evidence copied from the source repository. The extraction script performed no simulation. The separately recorded portable run passed its stated deterministic checks; the original class-based environment remains blocked by a verification-feature licence in the tested Starter editions. No functional coverage is claimed.

## Provenance and changes

Source commit: `df8d6f66898a08df75cd2071ddac7bbba9ba9b16`. Source path: `projects/apb-interface`.

[SOURCE_PROVENANCE.json](SOURCE_PROVENANCE.json) records checksums of every original file. `SOURCE_README.md` is the unchanged original README. No RTL or testbench functionality was changed during extraction. Source history remains available in the original repository; this is a snapshot, not a rewrite of its authorship.

## Next engineering work

Review the specification and implementation, run the supplied tests, add independently justified checks, and record actual results and known limitations. Waveform screenshots can be added later; no fabricated screenshots or coverage figures are needed.
